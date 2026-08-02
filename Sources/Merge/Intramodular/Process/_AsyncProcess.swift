//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Foundation
@_spi(Internal) import Swallow
import System

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    @MutexProtected
    public static var runningProcesses = [_AsyncProcess]()
}

public protocol _AsyncProcessDelegate {

}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public class _AsyncProcess: Logging {
    public typealias _StandardStreamsBuffer = _StandardInputOutputStreamsBuffer

    public let options: Set<Option>
    #if os(macOS)
    public let process: Process
    #endif
    private var _environmentVariables: EnvironmentVariables = .inherited
    public var environmentVariables: EnvironmentVariables {
        get {
            _environmentVariables
        }
        set {
            #if os(macOS)
            guard !process.isRunning else {
                preconditionFailure("Cannot modify environment variables while _AsyncProcess is running.")
            }
            #endif

            _environmentVariables = newValue
        }
    }
    package let standardStreamsBuffer: _StandardStreamsBuffer
    package let inputData: Data?

    private let publishers = _Publishers()
    package let processDidStart = _AsyncGate(initiallyOpen: false)
    package let processDidExit = _AsyncGate(initiallyOpen: false)

    @_OSUnfairLocked
    private var isWaiting = false

    package var _standardInputPipe: Pipe?
    package var _standardOutputPipe: Pipe?
    package var _standardErrorPipe: Pipe?

    @_OSUnfairLocked
    private var _resolvedRunResult: Result<_ProcessRunResult, Error>?

    public var standardInputPipe: Pipe? {
        #if os(macOS)
        if state == .notLaunch, _standardInputPipe == nil {
            _standardInputPipe = Pipe()
            process.standardInput = _standardInputPipe
        }
        return _standardInputPipe
        #else
        fatalError(.unsupported)
        #endif
    }

    #if os(macOS) || targetEnvironment(macCatalyst)
    @available(macCatalyst, unavailable)
    public init(
        existingProcess: Process?,
        options: [_AsyncProcess.Option]?,
        input: Data? = nil
    ) throws {
        #if os(macOS)
        let options: Set<_AsyncProcess.Option> = Set(options ?? [])

        if let existingProcess {
            assert(!existingProcess.isRunning)

            self.process = existingProcess
        } else {
            if options.contains(._useAuthorizationExecuteWithPrivileges) {
                assert(!options.contains(._useAppleScript))

                self.process = _SecAuthorizedProcess()
            } else if options.contains(._useAppleScript) {
                assert(!options.contains(._useAuthorizationExecuteWithPrivileges))

                self.process = OSAScriptProcess()
            } else {
                self.process = Process()
            }
        }

        self.options = Set(options)
        self.inputData = input
        self._environmentVariables = existingProcess?.environment.map(EnvironmentVariables.exact) ?? .inherited
        self.standardStreamsBuffer = _StandardStreamsBuffer(
            publishers: publishers,
            options: self.options
        )

        _registerAndSetUpIO(existingProcess: existingProcess)
        if input != nil {
            _standardInputPipe = Pipe()
            process.standardInput = _standardInputPipe
        }
        #else
        fatalError(.unavailable)
        #endif
    }

    public init(
        executableURL: URL?,
        arguments: [String]?,
        environmentVariables: EnvironmentVariables,
        currentDirectoryURL: URL?,
        options: [_AsyncProcess.Option]? = nil,
        input: Data? = nil
    ) throws {
        #if os(macOS)
        let options: Set<_AsyncProcess.Option> = Set(options ?? [])

        if options.contains(._useAuthorizationExecuteWithPrivileges) {
            assert(!options.contains(._useAppleScript))

            self.process = _SecAuthorizedProcess()
        } else if options.contains(._useAppleScript) {
            assert(!options.contains(._useAuthorizationExecuteWithPrivileges))

            self.process = OSAScriptProcess()
        } else {
            self.process = Process()
        }

        process.executableURL = executableURL
        process.arguments = arguments
        if let currentDirectoryURL {
            process.currentDirectoryURL = currentDirectoryURL._fromURLToFileURL()
        }

        self.options = options
        self.inputData = input
        self._environmentVariables = environmentVariables
        self.standardStreamsBuffer = _StandardStreamsBuffer(
            publishers: publishers,
            options: self.options
        )

        _registerAndSetUpIO(existingProcess: nil)
        if input != nil {
            _standardInputPipe = Pipe()
            process.standardInput = _standardInputPipe
        }
        #else
        fatalError(.unavailable)
        #endif
    }

    public convenience init(
        executableURL: URL?,
        arguments: [String]?,
        environment: [String: String]?,
        currentDirectoryURL: URL?,
        options: [_AsyncProcess.Option]? = nil,
        input: Data? = nil
    ) throws {
        try self.init(
            executableURL: executableURL,
            arguments: arguments,
            environmentVariables: environment.map(EnvironmentVariables.exact) ?? .inherited,
            currentDirectoryURL: currentDirectoryURL,
            options: options,
            input: input
        )
    }
    #else
    public init() throws {
        throw Never.Reason.unavailable
    }

    public init(
        executableURL: URL?,
        arguments: [String]?,
        environmentVariables: EnvironmentVariables,
        currentDirectoryURL: URL?,
        options: [_AsyncProcess.Option]? = nil,
        input: Data? = nil
    ) throws {
        throw Never.Reason.unsupported
    }

    public init(
        executableURL: URL?,
        arguments: [String]?,
        environment: [String: String]?,
        currentDirectoryURL: URL?,
        options: [_AsyncProcess.Option]? = nil,
        input: Data? = nil
    ) throws {
        throw Never.Reason.unsupported
    }
    #endif

    #if os(macOS)
    private func _registerAndSetUpIO(existingProcess: Process?) {
        Self.$runningProcesses.withCriticalRegion {
            $0.append(self)
        }

        _setUpStdinStdoutStderr(existingProcess: existingProcess)
    }

    #endif
}

#if os(macOS) || targetEnvironment(macCatalyst)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension _AsyncProcess {
    #if os(macOS)
    public var state: State {
        if process.isRunning {
            return .running
        }

        var terminationReason: ProcessTerminationError?

        if process is _SecAuthorizedProcess {
            if !processDidStart.isOpen {
                return .notLaunch
            }
        } else {
            if !processDidStart.isOpen && process.processIdentifier == 0 {
                return .notLaunch
            }
        }

        terminationReason = ProcessTerminationError(_from: process)

        if let terminationReason = terminationReason {
            return .terminated(
                status: Int(process.terminationStatus),
                reason: terminationReason.reason
            )
        }

        return .notLaunch
    }
    #else
    public var state: State {
        return .notLaunch
    }
    #endif

    @discardableResult
    public func run() async throws -> _ProcessRunResult {
        #if os(macOS)
        return try await withTaskCancellationHandler {
            if let _resolvedRunResult {
                return try _resolvedRunResult.get()
            }

            guard state != .running else {
                try await processDidExit.enter()

                return try _resolvedRunResult.unwrap().get()
            }

            do {
                try Task.checkCancellation()

                try await _runUnconditionally()
                try Task.checkCancellation()

                await _spinUntilProcessExit()

                return try _resolvedRunResult.unwrap().get()
            } catch {
                if Task.isCancelled {
                    // Cancellation can arrive while `Process.run()` is still
                    // assigning the PID. Retry the tree termination after the
                    // launch continuation has unwound so descendants created
                    // in that race are not left holding our pipes open.
                    self._terminate()
                } else {
                    self._resolvedRunResult = .failure(error)
                }

                throw error
            }
        } onCancel: {
            self._terminate()
        }
        #else
        fatalError(.unsupported)
        #endif
    }

    @_disfavoredOverload
    public func run() {
        Task {
            do {
                try await self.run()
            } catch {
                runtimeIssue(error)
            }
        }
    }

    public func terminate() async throws {
        #if os(macOS)
        guard process.isRunning else {
            return
        }

        process.terminate()
        #else
        fatalError(.unsupported)
        #endif
    }

    public func _terminate() {
        #if os(macOS)
        let processIdentifier = process.processIdentifier
        guard processIdentifier > 1, processIdentifier != getpid() else {
            return
        }

        Task.detached(priority: .userInitiated) {
            _ = await ProcessGroupTimeoutGuard.terminateProcessTree(
                rootPID: processIdentifier,
                gracePeriod: .milliseconds(100),
                pollInterval: .milliseconds(10)
            )
        }
        #endif
    }
}
#else
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    public var state: State {
        return .notLaunch
    }

    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func run() async throws -> _ProcessRunResult {
        fatalError(.unavailable)
    }
}
#endif

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    public var isRunning: Bool {
        state == .running
    }
}

#if os(macOS)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension _AsyncProcess {
    private func _setUpStdinStdoutStderr(
        existingProcess: Process?
    ) {
        if let existingProcess {
            assert(process === existingProcess)
        }

        if let existingStandardOutputPipe = existingProcess?.standardOutput as? Pipe {
            _standardOutputPipe = .some(existingStandardOutputPipe)
        } else {
            _standardOutputPipe = Pipe()

            process.standardOutput = _standardOutputPipe
        }

        if let existingStandardErrorPipe = existingProcess?.standardError as? Pipe {
            _standardErrorPipe = .some(existingStandardErrorPipe)
        } else {
            _standardErrorPipe = Pipe()

            process.standardError = _standardErrorPipe
        }
    }

    private func _spinUntilProcessExit() async {
        while process.isRunning {
            runtimeIssue("The process is expected to have stopped running.")

            await Task.yield()
        }

        do {
            try Task.checkCancellation()
        } catch {
            if teardownSequence.isEmpty {
                do {
                    try await terminate()
                } catch {
                    runtimeIssue(error)
                }
            } else {
                await teardown(using: teardownSequence)
            }
        }

        assert(!process.isRunning)
    }

    private func _runUnconditionally() async throws {
        var inputWriterTask: Task<Void, Error>?

        do {
            guard !isWaiting else {
                return
            }

            isWaiting = true

            guard let standardOutputPipe = _standardOutputPipe,
                let standardErrorPipe = _standardErrorPipe
            else {
                assertionFailure()

                return
            }

            let standardOutputReader = standardOutputPipe._makeAsyncReader()
            let standardErrorReader = standardErrorPipe._makeAsyncReader()

            func readData() async throws {
                if !options.contains(._useAuthorizationExecuteWithPrivileges) {
                    try await _readStdoutStderrUntilEnd(
                        standardOutputPipe: standardOutputPipe,
                        standardErrorPipe: standardErrorPipe,
                        standardOutputReader: standardOutputReader,
                        standardErrorReader: standardErrorReader
                    )
                } else {
                    try await _readStdoutStderrUntilEnd(
                        standardOutputPipe: standardOutputPipe,
                        standardErrorPipe: standardErrorPipe,
                        standardOutputReader: standardOutputReader,
                        standardErrorReader: standardErrorReader,
                        ignoreStderr: true
                    )
                }
            }

            @MutexProtected
            var launchError: Error? = nil
            let readStdoutStderrTask = Task<Void, Error>.detached(priority: .high) {
                try await readData()
            }
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    @MutexProtected
                    var didResume: Bool = false

                    process.terminationHandler = { (process: Process) in
                        Task<Void, Never>.detached(priority: .userInitiated) {
                            await Task.yield()

                            if let terminationError = process.terminationError {
                                continuation.resume(throwing: terminationError)
                            } else {
                                assert(!process.isRunning)

                                continuation.resume()
                            }

                            $didResume.assignedValue = true
                        }
                    }

                    let processWillRunTask = _processWillRun()

                    do {
                        if let environmentVariables = environmentVariables.resolvingForProcessLaunch() {
                            process.environment = environmentVariables
                        }

                        try process.run()

                        if let inputData,
                           let inputHandle = _standardInputPipe?.fileHandleForWriting
                        {
                            inputWriterTask = Task.detached(priority: .high) {
                                do {
                                    try inputHandle.write(contentsOf: inputData)
                                    try inputHandle.close()
                                } catch {
                                    try? inputHandle.close()
                                    throw error
                                }
                            }
                        }
                    } catch {
                        $launchError.assignedValue = error
                        processWillRunTask.cancel()

                        try? _standardOutputPipe?.fileHandleForWriting.close()
                        try? _standardErrorPipe?.fileHandleForWriting.close()
                        try? _standardInputPipe?.fileHandleForWriting.close()

                        continuation.resume(throwing: error)
                    }

                    _processExited(didResume: { didResume })
                }
            } catch {
                if let launchError {
                    readStdoutStderrTask.cancel()
                    _ = try? await readStdoutStderrTask.value

                    try? _standardOutputPipe?.fileHandleForReading.close()
                    try? _standardErrorPipe?.fileHandleForReading.close()

                    throw launchError
                } else {
                    runtimeIssue(error)
                }
            }

            try await readStdoutStderrTask.value

            if let inputWriterTask {
                do {
                    try await inputWriterTask.value
                } catch {
                    // A process that exits before consuming all input closes
                    // the read end of the pipe. That is expected for commands
                    // which intentionally stop reading early.
                    if process.isRunning {
                        throw error
                    }
                }
            }

            assert(!process.isRunning)

            do {
                try _standardOutputPipe?.fileHandleForReading.close()
                try _standardErrorPipe?.fileHandleForReading.close()
                if inputWriterTask == nil {
                    try _standardInputPipe?.fileHandleForWriting.close()
                }
            } catch {
                runtimeIssue("Failed to close a pipe.")
            }

            await _stashRunResultAndTeardownProcess(error: nil)
        } catch {
            if let inputWriterTask {
                inputWriterTask.cancel()
                try? _standardInputPipe?.fileHandleForWriting.close()
                try? await inputWriterTask.value
            } else {
                try? _standardInputPipe?.fileHandleForWriting.close()
            }
            await _stashRunResultAndTeardownProcess(error: error)

            throw error
        }
    }

    private func _readStdoutStderrUntilEnd(
        standardOutputPipe: Pipe,
        standardErrorPipe: Pipe,
        standardOutputReader: Pipe._AsyncReader,
        standardErrorReader: Pipe._AsyncReader,
        ignoreStderr: Bool = false
    ) async throws {
        try await withTaskCancellationHandler {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    _ = try await standardOutputReader.readToEnd { data in
                        try await self.__handleData(data, forPipe: standardOutputPipe)
                    }
                }

                group.addTask {
                    _ = try await standardErrorReader.readToEnd { data in
                        guard !ignoreStderr else {
                            return
                        }

                        try await self.__handleData(data, forPipe: standardErrorPipe)
                    }
                }

                try await group.waitForAll()
                }
            } onCancel: {
                self._terminate()
            }
        }

    private func __handleData(
        _ data: Data,
        forPipe pipe: Pipe
    ) async throws {
        let pipeName: Process.PipeName = try self.name(of: pipe)

        await standardStreamsBuffer.record(data: data, forPipe: pipe, pipeName: pipeName)
    }

    private func _processWillRun() -> Task<Void, Never> {
        assert(!process.isRunning)

        return Task.detached(priority: .userInitiated) { @MainActor in
            while !Task.isCancelled && !self.process.isRunning && self.process.processIdentifier == 0 {
                await Task.yield()

                try? await Task.sleep(.milliseconds(10))
            }

            if !Task.isCancelled {
                self.processDidStart.open()
            }
        }
    }

    /// Should be called prior to `_stashRunResultAndTeardown`.
    private func _processExited(
        didResume: @escaping () -> Bool
    ) {
        Task {
            try await Task.sleep(.milliseconds(300))

            await Task.yield()

            if !process.isRunning && !didResume() {
                runtimeIssue("\(description) exited.")
            }
        }
    }

    @discardableResult
    private func _stashRunResultAndTeardownProcess(
        error: Error?
    ) async -> Result<Process.RunResult, Error> {
        Self.$runningProcesses.withCriticalRegion {
            $0.removeAll(where: { $0 === self })
        }

        let result: Result<Process.RunResult, Error>

        if let error {
            result = .failure(error)
        } else {
            result = await Result(
                catching: { () -> Process.RunResult in
                    let stdoutData = await self.standardStreamsBuffer._standardOutputData()
                    let stderrData = await self.standardStreamsBuffer._standardErrorData()
                    let stdout = String(data: stdoutData, encoding: .utf8)
                    let stderr = String(data: stderrData, encoding: .utf8)

                    let result = Process.RunResult(
                        process: process,
                        stdout: stdoutData,
                        stderr: stderrData,
                        terminationError: process.terminationError.map {
                            ProcessTerminationError(
                                _from: $0.process,
                                stdout: stdout,
                                stderr: stderr
                            )
                        }
                    )

                    return result
                })
        }

        await standardStreamsBuffer.closeFileHandles()

        self._resolvedRunResult = result

        if processDidStart.isOpen || process.processIdentifier != 0 {
            publishers.exitPublisher.send(process.terminationStatus)
        }

        processDidExit.open()

        return result
    }
}
#endif

#if os(macOS)
@available(macCatalyst, unavailable)
extension _AsyncProcess {
    public func _standardOutputPublisher() -> AnyPublisher<Data, Never> {
        publishers.standardOutputPublisher
            .compactMap({ (data) -> [Just<String>]? in
                String(data: data, encoding: .utf8)?.lines(omittingEmpty: false).map({
                    Just(String($0))
                })
            })
            .flatMap({ Publishers.ConcatenateMany($0) })
            .compactMap({ $0.data(using: .utf8) })
            .eraseToAnyPublisher()
    }

    public func _standardErrorPublisher() -> AnyPublisher<Data, Never> {
        publishers.standardErrorPublisher.eraseToAnyPublisher()
    }

    public func _exitPublisher() -> AnyPublisher<Int32, Never> {
        publishers.exitPublisher.eraseToAnyPublisher()
    }

    public func _send(data: Data) throws {
        runtimeIssue("Send not allowed")
    }
}
#endif

// MARK: - Conformances

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess: CustomStringConvertible {
    public var description: String {
        #if os(macOS)
        Process._makeDescriptionPrefix(
            launchPath: self.process.launchPath,
            arguments: self.process.arguments
        )
        #else
        fatalError(.unsupported)
        #endif
    }
}

// MARK: - Auxiliary

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    public enum State: Equatable {
        case notLaunch
        case running
        case terminated(status: Int, reason: ProcessTerminationError.Reason)

        public var isTerminated: Bool {
            guard case .terminated = self else {
                return false
            }

            return true
        }
    }
}

@available(macOS 11.0, *)
@available(macCatalyst 16.0, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public enum _AsyncProcessOption: Hashable {
    case _useAppleScript
    case _useAuthorizationExecuteWithPrivileges
    case _forwardStdoutStderr(to: _ProcessStandardOutputSink)
    case _teardown([_AsyncProcessTeardownStep])

    public static var _forwardStdoutStderr: Self {
        ._forwardStdoutStderr(to: .terminal)
    }

    public var _stdoutStderrSink: _ProcessStandardOutputSink {
        guard case let ._forwardStdoutStderr(sink) = self else {
            return .null
        }

        return sink
    }

    public var _teardownSequence: [_AsyncProcessTeardownStep] {
        guard case let ._teardown(sequence) = self else {
            return []
        }

        return sequence
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    public typealias Option = _AsyncProcessOption
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    struct _Publishers {
        let standardOutputPublisher = ReplaySubject<Data, Never>()
        let standardErrorPublisher = ReplaySubject<Data, Never>()
        let exitPublisher = ReplaySubject<Int32, Never>()
    }
}
