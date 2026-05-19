//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Darwin
import Foundation

/// Domain-agnostic utility for terminating the subprocess tree rooted at this
/// process. Useful any time a parent needs to bound the wall-clock lifetime
/// of work it has delegated to subprocesses.
///
/// ## Why this is not trivial
///
/// A naive "put ourselves in a process group, then `killpg`" doesn't reach
/// every descendant: any subprocess that goes through an intermediate
/// interactive shell (for example a tool invoked via `/bin/zsh -l -c`) is
/// reparented into the shell's freshly-allocated job-control process group,
/// not ours. This utility therefore unions two enumeration strategies — a
/// PPID tree walk rooted at our PID, and a `pgrep -g` query for our own
/// process group — to find the full set of descendants.
///
/// ## Termination protocol
///
/// `terminateDescendantsThenKill` implements a verification-based cascade:
/// SIGTERM the current tree, poll every `pollInterval` to detect natural
/// death, and only escalate to SIGKILL for processes that survive the grace
/// window. Each PID is then verified with `kill(pid, 0)` so callers receive
/// an authoritative per-process outcome rather than just the list of signals
/// sent.
///
/// ## Safety invariants
///
/// - `getpid()` is never signalled — the caller keeps running.
/// - PIDs 0 (kernel) and 1 (launchd) are unconditionally filtered out.
/// - Negative or non-positive PIDs are rejected so a malformed `ps` line
///   can't be interpreted as a process-group broadcast.
/// - Helper subprocesses (`/bin/ps`, `/usr/bin/pgrep`) are bounded to
///   `_helperSubprocessTimeout` so a wedged kernel sysctl never deadlocks
///   the kill path.
public enum ProcessGroupTimeoutGuard {

    // MARK: - Public types

    /// Outcome of the `setpgid(0, 0)` call.
    public enum EstablishResult: Equatable, Sendable {
        /// `setpgid(0, 0)` succeeded — we are now the leader of a fresh pgrp.
        case becameLeader
        /// `setpgid` returned `EPERM`; on macOS this means we are already a
        /// session leader (commonly when running under `launchd`). Signalling
        /// still works through the PPID tree walk; pgrp enumeration covers
        /// whatever group we were already in.
        case alreadySessionLeader
        /// `setpgid` failed for a reason other than `EPERM`. Termination
        /// still works via PPID walking.
        case failed(errno: Int32)

        public var isOk: Bool {
            switch self {
            case .becameLeader, .alreadySessionLeader: return true
            case .failed: return false
            }
        }
    }

    /// Per-process termination outcome.
    public enum TerminationOutcome: String, Hashable, Sendable {
        /// Process exited within the grace period after SIGTERM.
        case terminatedGracefully
        /// Process required SIGKILL to die.
        case forciblyKilled
        /// Process survived SIGKILL — should not happen for normal processes
        /// (uninterruptible kernel sleep or PID reuse race).
        case survived
        /// Process was already gone (ESRCH) when we tried to signal it.
        case alreadyGone
    }

    public struct TerminationReport: Sendable {
        public let outcomes: [pid_t: TerminationOutcome]
        public let commandByPID: [pid_t: String]
        public let elapsed: Duration

        public init(
            outcomes: [pid_t: TerminationOutcome],
            commandByPID: [pid_t: String],
            elapsed: Duration
        ) {
            self.outcomes = outcomes
            self.commandByPID = commandByPID
            self.elapsed = elapsed
        }

        public var pids: [pid_t] { outcomes.keys.sorted() }
        public var signalCount: Int { outcomes.count }
        public var survivorCount: Int {
            outcomes.values.filter { (outcome: TerminationOutcome) -> Bool in outcome == .survived }.count
        }

        public var summary: String {
            let buckets: [(TerminationOutcome, String)] = [
                (.terminatedGracefully, "graceful"),
                (.forciblyKilled, "forced"),
                (.survived, "survived"),
                (.alreadyGone, "already-gone"),
            ]
            let parts: [String] = buckets.compactMap { (outcome: TerminationOutcome, label: String) -> String? in
                let count: Int = outcomes.values.filter { (candidate: TerminationOutcome) -> Bool in candidate == outcome }.count
                return count > 0 ? "\(count) \(label)" : nil
            }
            return "[\(parts.joined(separator: ", "))]"
        }

        public var commandSummary: String {
            let counts: [(command: String, count: Int)] = Dictionary(grouping: interruptedCommandBasenames, by: { (command: String) -> String in command })
                .map { (command: String, values: [String]) in (command: command, count: values.count) }
                .sorted { (lhs: (command: String, count: Int), rhs: (command: String, count: Int)) -> Bool in
                    if lhs.count == rhs.count { return lhs.command < rhs.command }
                    return lhs.count > rhs.count
                }

            guard !counts.isEmpty else {
                return ""
            }

            return counts.prefix(8).map { (entry: (command: String, count: Int)) -> String in "\(entry.command)×\(entry.count)" }.joined(separator: ", ")
        }

        public var interruptedCommandBasenames: [String] {
            outcomes.keys.compactMap { (pid: pid_t) -> String? in
                commandByPID[pid]?.split(separator: "/").last.map { (component: Substring) -> String in String(component) }
            }
        }

        public var interruptedSwiftPackageManifestCommands: [String] {
            Array(
                Set(
                    interruptedCommandBasenames.filter { (command: String) -> Bool in command.hasSuffix("-manifest") }
                )
            )
            .sorted()
        }

        public var interruptedSwiftCompilerCommands: [String] {
            Array(
                Set(
                    interruptedCommandBasenames.filter { (command: String) -> Bool in
                        command == "swift-driver" || command == "swift-frontend" || command == "swiftc"
                    }
                )
            )
            .sorted()
        }
    }

    public struct ProcessSnapshot: Hashable, Sendable {
        public let pid: pid_t
        public let ppid: pid_t
    }

    // MARK: - Public API

    /// Sets up a dedicated process group for this process. Idempotent: safe to
    /// call more than once; subsequent calls return the original outcome.
    @discardableResult
    public static func establish() -> EstablishResult {
        _stateLock.lock()
        defer { _stateLock.unlock() }

        if let cached: EstablishResult = _cachedEstablishResult {
            return cached
        }

        let result: EstablishResult
        if setpgid(0, 0) == 0 {
            result = .becameLeader
        } else {
            // Capture errno immediately — any Swift call (even allocation)
            // can clobber thread-local errno before we read it.
            let capturedErrno: Int32 = errno
            result = capturedErrno == EPERM ? .alreadySessionLeader : .failed(errno: capturedErrno)
        }
        _cachedEstablishResult = result
        return result
    }

    /// Returns the current descendant snapshot without sending any signals.
    /// Useful for diagnostics and dry-run inspection.
    public static func snapshotDescendants() -> [ProcessSnapshot] {
        let myPid: pid_t = getpid()
        let treeSnapshots: [ProcessSnapshot] = _walkDescendants(of: myPid)
        let pgrpPids: Set<pid_t> = Set(_listProcessGroupMembers(pgrp: getpgrp())).subtracting([myPid])
        let treePids: Set<pid_t> = Set(treeSnapshots.map { (snapshot: ProcessSnapshot) -> pid_t in snapshot.pid })
        let pgrpOnly: [ProcessSnapshot] = pgrpPids.subtracting(treePids).map { (pid: pid_t) in
            ProcessSnapshot(pid: pid, ppid: -1)
        }
        return (treeSnapshots + pgrpOnly)
            .filter { (snap: ProcessSnapshot) in _isSignallable(snap.pid) }
            .sorted { (lhs: ProcessSnapshot, rhs: ProcessSnapshot) -> Bool in lhs.pid < rhs.pid }
    }

    /// Sends `signal` to every descendant of this process and every member of
    /// its process group, skipping the caller and any non-signallable PIDs
    /// (kernel, launchd, our helper subprocesses). Returns the PIDs that
    /// received the signal — i.e. were live at signal time.
    @discardableResult
    public static func terminateDescendants(signal: Int32) -> [pid_t] {
        let targets: [pid_t] = snapshotDescendants().map { (snapshot: ProcessSnapshot) -> pid_t in snapshot.pid }
        var signalled: [pid_t] = []
        for pid: pid_t in targets {
            if kill(pid, signal) == 0 {
                signalled.append(pid)
            }
            // `kill` returning -1 with ESRCH means the process already exited;
            // anything else (EPERM, EINVAL) is silently tolerated — there's no
            // recovery available at this layer.
        }
        return signalled
    }

    /// Verification-based termination cascade.
    ///
    /// 1. SIGTERM every current descendant.
    /// 2. Poll each survivor every `pollInterval` until either it dies (good)
    ///    or `gracePeriod` elapses.
    /// 3. SIGKILL processes that didn't exit gracefully, plus any new
    ///    descendants that appeared during the grace window.
    /// 4. Briefly poll again to confirm SIGKILL took effect.
    /// 5. Return a per-PID `TerminationReport` describing what happened.
    @discardableResult
    public static func terminateDescendantsThenKill(
        gracePeriod: Duration = .seconds(2),
        pollInterval: Duration = .milliseconds(100)
    ) async -> TerminationReport {
        let clock: ContinuousClock = ContinuousClock()
        let startedAt: ContinuousClock.Instant = clock.now

        var outcomes: [pid_t: TerminationOutcome] = [:]

        // Phase 1: SIGTERM the current tree.
        var commandByPID: [pid_t: String] = [:]
        let sigtermTargets: [pid_t] = snapshotDescendants().map { (snapshot: ProcessSnapshot) -> pid_t in snapshot.pid }
        commandByPID.merge(_processCommands(for: sigtermTargets), uniquingKeysWith: { current, _ in current })
        for pid: pid_t in sigtermTargets {
            if kill(pid, SIGTERM) == 0 {
                outcomes[pid] = .survived // tentative — may upgrade to graceful
            } else if errno == ESRCH {
                outcomes[pid] = .alreadyGone
            }
        }

        // Phase 2: poll for natural death.
        let graceDeadline: ContinuousClock.Instant = startedAt.advanced(by: gracePeriod)
        while clock.now < graceDeadline {
            var anyStillAlive: Bool = false
            for (pid, outcome): (pid_t, TerminationOutcome) in outcomes where outcome == .survived {
                if !_isAlive(pid) {
                    outcomes[pid] = .terminatedGracefully
                } else {
                    anyStillAlive = true
                }
            }
            if !anyStillAlive { break }
            try? await Task.sleep(for: pollInterval)
        }

        // Phase 3: SIGKILL survivors + any new descendants that appeared during grace.
        let survivors: [pid_t] = outcomes.compactMap { (pid: pid_t, outcome: TerminationOutcome) -> pid_t? in
            outcome == .survived ? pid : nil
        }
        let currentTargets: Set<pid_t> = Set(snapshotDescendants().map { (snapshot: ProcessSnapshot) -> pid_t in snapshot.pid })
        commandByPID.merge(_processCommands(for: Array(currentTargets)), uniquingKeysWith: { current, _ in current })
        let sigkillTargets: Set<pid_t> = Set(survivors).union(currentTargets)
        for pid: pid_t in sigkillTargets {
            if kill(pid, SIGKILL) == 0 {
                if outcomes[pid] == nil {
                    outcomes[pid] = .survived // newly seen, tentative
                }
            } else if errno == ESRCH, outcomes[pid] == nil {
                outcomes[pid] = .alreadyGone
            }
        }

        // Phase 4: brief verification — SIGKILL is uncatchable, so a single
        // short poll cycle suffices. If anything still appears alive, it's
        // wedged in an uninterruptible kernel state (rare).
        let verifyDeadline: ContinuousClock.Instant = clock.now.advanced(by: .milliseconds(500))
        while clock.now < verifyDeadline {
            var anyAlive: Bool = false
            for (pid, outcome): (pid_t, TerminationOutcome) in outcomes where outcome == .survived {
                if !_isAlive(pid) {
                    outcomes[pid] = .forciblyKilled
                } else {
                    anyAlive = true
                }
            }
            if !anyAlive { break }
            try? await Task.sleep(for: pollInterval)
        }

        return TerminationReport(
            outcomes: outcomes,
            commandByPID: commandByPID,
            elapsed: clock.now - startedAt
        )
    }

    /// Blocking variant used by wall-clock watchdogs that must fire even when
    /// Swift's cooperative executor is occupied by subprocess I/O.
    @discardableResult
    public static func terminateDescendantsThenKillBlocking(
        gracePeriodSeconds: TimeInterval = 2,
        pollIntervalSeconds: TimeInterval = 0.1
    ) -> TerminationReport {
        let startedAt: Date = Date()
        var outcomes: [pid_t: TerminationOutcome] = [:]
        var commandByPID: [pid_t: String] = [:]

        let sigtermTargets: [pid_t] = snapshotDescendants().map { (snapshot: ProcessSnapshot) -> pid_t in snapshot.pid }
        commandByPID.merge(_processCommands(for: sigtermTargets), uniquingKeysWith: { current, _ in current })
        for pid: pid_t in sigtermTargets {
            if kill(pid, SIGTERM) == 0 {
                outcomes[pid] = .survived
            } else if errno == ESRCH {
                outcomes[pid] = .alreadyGone
            }
        }

        let graceDeadline: Date = Date().addingTimeInterval(gracePeriodSeconds)
        while Date() < graceDeadline {
            var anyStillAlive: Bool = false
            for (pid, outcome): (pid_t, TerminationOutcome) in outcomes where outcome == .survived {
                if !_isAlive(pid) {
                    outcomes[pid] = .terminatedGracefully
                } else {
                    anyStillAlive = true
                }
            }
            if !anyStillAlive {
                break
            }
            Thread.sleep(forTimeInterval: pollIntervalSeconds)
        }

        let survivors: [pid_t] = outcomes.compactMap { (pid: pid_t, outcome: TerminationOutcome) -> pid_t? in
            outcome == .survived ? pid : nil
        }
        let currentTargets: Set<pid_t> = Set(snapshotDescendants().map { (snapshot: ProcessSnapshot) -> pid_t in snapshot.pid })
        commandByPID.merge(_processCommands(for: Array(currentTargets)), uniquingKeysWith: { current, _ in current })
        let sigkillTargets: Set<pid_t> = Set(survivors).union(currentTargets)
        for pid: pid_t in sigkillTargets {
            if kill(pid, SIGKILL) == 0 {
                if outcomes[pid] == nil {
                    outcomes[pid] = .survived
                }
            } else if errno == ESRCH, outcomes[pid] == nil {
                outcomes[pid] = .alreadyGone
            }
        }

        let verifyDeadline: Date = Date().addingTimeInterval(0.5)
        while Date() < verifyDeadline {
            var anyAlive: Bool = false
            for (pid, outcome): (pid_t, TerminationOutcome) in outcomes where outcome == .survived {
                if !_isAlive(pid) {
                    outcomes[pid] = .forciblyKilled
                } else {
                    anyAlive = true
                }
            }
            if !anyAlive {
                break
            }
            Thread.sleep(forTimeInterval: pollIntervalSeconds)
        }

        let elapsedNanoseconds: Int64 = Int64(max(0, Date().timeIntervalSince(startedAt) * 1_000_000_000))
        return TerminationReport(
            outcomes: outcomes,
            commandByPID: commandByPID,
            elapsed: .nanoseconds(elapsedNanoseconds)
        )
    }

    // MARK: - Internals

    private static let _stateLock: NSLock = NSLock()
    nonisolated(unsafe) private static var _cachedEstablishResult: EstablishResult?

    /// PIDs we must never signal: kernel (0), launchd (1).
    private static let _untouchablePIDs: Set<pid_t> = [0, 1]

    /// Upper bound on helper subprocess execution. `ps` and `pgrep` should
    /// complete in milliseconds; a multi-second timeout is a safety net
    /// against runaway forking or sysctl wedges.
    private static let _helperSubprocessTimeout: TimeInterval = 5

    private static func _isSignallable(_ pid: pid_t) -> Bool {
        pid != getpid() && !_untouchablePIDs.contains(pid) && pid > 0
    }

    /// `kill(pid, 0)` returns 0 if we have permission to signal the process
    /// (i.e. it exists), -1 with ESRCH if it has exited, or -1 with EPERM if
    /// it exists but is owned by another user — for our purposes EPERM still
    /// means "alive".
    private static func _isAlive(_ pid: pid_t) -> Bool {
        if kill(pid, 0) == 0 { return true }
        return errno == EPERM
    }

    /// Walks the PPID tree rooted at `root`, returning descendant snapshots
    /// (not including `root` itself).
    ///
    /// Uses a single `ps -A` snapshot for a consistent view. Processes that
    /// exit between snapshot and signal-time will report ESRCH from `kill`,
    /// which we tolerate.
    private static func _walkDescendants(of root: pid_t) -> [ProcessSnapshot] {
        guard let output: String = _runHelperSubprocess(
            path: "/bin/ps",
            arguments: ["-A", "-o", "pid=,ppid="]
        ) else { return [] }

        var childrenByParent: [pid_t: [pid_t]] = [:]
        var ppidByPid: [pid_t: pid_t] = [:]
        for line: Substring in output.split(separator: "\n") {
            let parts: [Substring] = line.split(whereSeparator: { (c: Character) in c.isWhitespace })
            guard parts.count >= 2,
                  let pid: pid_t = pid_t(parts[0]),
                  let ppid: pid_t = pid_t(parts[1])
            else { continue }
            childrenByParent[ppid, default: []].append(pid)
            ppidByPid[pid] = ppid
        }

        var result: [ProcessSnapshot] = []
        var queue: [pid_t] = [root]
        var visited: Set<pid_t> = [root]
        while let next: pid_t = queue.first {
            queue.removeFirst()
            for child: pid_t in childrenByParent[next] ?? [] where !visited.contains(child) {
                visited.insert(child)
                result.append(ProcessSnapshot(pid: child, ppid: next))
                queue.append(child)
            }
        }
        return result
    }

    private static func _processCommands(for pids: [pid_t]) -> [pid_t: String] {
        let uniquePids: [pid_t] = Array(Set(pids.filter { (pid: pid_t) -> Bool in _isSignallable(pid) })).sorted()
        guard !uniquePids.isEmpty else {
            return [:]
        }

        let pidList: String = uniquePids.map { (pid: pid_t) -> String in String(pid) }.joined(separator: ",")
        guard let output: String = _runHelperSubprocess(
            path: "/bin/ps",
            arguments: ["-p", pidList, "-o", "pid=,comm="]
        ) else {
            return [:]
        }

        var result: [pid_t: String] = [:]
        for line: Substring in output.split(separator: "\n") {
            let trimmed: String = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let separator: String.Index = trimmed.firstIndex(where: { (character: Character) in character.isWhitespace }) else {
                continue
            }
            let pidText: Substring = trimmed[..<separator]
            let command: String = trimmed[separator...]
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let pid: pid_t = pid_t(pidText), !command.isEmpty {
                result[pid] = command
            }
        }
        return result
    }

    /// Reads PIDs belonging to `pgrp` via `pgrep -g <pgrp>`.
    ///
    /// macOS `ps -g <n>` is **not** a pgrp filter — it controls
    /// session-leader inclusion. The portable way to enumerate processes by
    /// group id is `pgrep -g`.
    private static func _listProcessGroupMembers(pgrp: pid_t) -> [pid_t] {
        guard let output: String = _runHelperSubprocess(
            path: "/usr/bin/pgrep",
            arguments: ["-g", String(pgrp)]
        ) else { return [] }

        return output
            .split(whereSeparator: { (c: Character) in c.isWhitespace })
            .compactMap { (substring: Substring) in pid_t(substring) }
    }

    /// Runs a short-lived helper subprocess (`ps`/`pgrep`) with a wall-clock
    /// timeout. Returns its stdout on success, nil on launch failure or
    /// timeout. Stderr is discarded.
    private static func _runHelperSubprocess(path: String, arguments: [String]) -> String? {
        let process: Process = Process()
        process.launchPath = path
        process.arguments = arguments
        let stdoutPipe: Pipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }

        // Wait with a bounded deadline. `Process.waitUntilExit` has no
        // timeout overload, so we poll `isRunning` ourselves.
        let deadline: Date = Date().addingTimeInterval(_helperSubprocessTimeout)
        while process.isRunning {
            if Date() > deadline {
                process.terminate()
                Thread.sleep(forTimeInterval: 0.05)
                if process.isRunning { kill(process.processIdentifier, SIGKILL) }
                return nil
            }
            Thread.sleep(forTimeInterval: 0.01)
        }

        let data: Data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}

#endif
