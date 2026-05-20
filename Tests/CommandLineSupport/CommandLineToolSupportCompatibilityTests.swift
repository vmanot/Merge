#if os(macOS)

import CommandLineToolSupport
import Combine
import Foundation
import Merge
import Testing

final class LegacyAnyCommandLineToolCompatibilityTool: AnyCommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "legacy-any-command-line-tool"
    }
}

@Suite
struct CommandLineToolSupportCompatibilityTests {
    @Test("AnyCommandLineTool _run(command:) records shell command lines")
    func anyCommandLineToolRunCommandRecordsShellCommandLine() async throws {
        let tool = LegacyAnyCommandLineToolCompatibilityTool()
        let record = try await tool._run(
            command: "printf raw-shell",
            applying: .standardStreamMirroring(.disabled)
        )

        guard case .shellCommandLine(let commandLine) = record.source else {
            Issue.record("Expected AnyCommandLineTool._run(command:) to record a shell command line.")
            return
        }

        #expect(commandLine == "printf raw-shell")
        #expect(record.tool === tool)
        #expect(record.invocation == nil)
        #expect(record.commandLine == commandLine)
        #expect(record.stdoutString == "raw-shell")
    }

    @Test("AnyCommandLineTool _run(command:) does not require CommandLineTool conformance")
    func anyCommandLineToolRunCommandDoesNotRequireCommandLineToolConformance() async throws {
        let tool = LegacyAnyCommandLineToolCompatibilityTool()
        let record = try await tool._run(
            command: "printf raw-base",
            applying: .standardStreamMirroring(.disabled)
        )

        #expect(record.tool === tool)
        #expect(record.commandLine == "printf raw-base")
        #expect(record.stdoutString == "raw-base")
    }

    @Test("AnyCommandLineTool _run(command:) applies scoped SystemShell configuration")
    func anyCommandLineToolRunCommandAppliesScopedSystemShellConfiguration() async throws {
        let directoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build", isDirectory: true)
            .appendingPathComponent(
                "merge-command-line-tool-run-\(UUID().uuidString)",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let record = try await LegacyAnyCommandLineToolCompatibilityTool()._run(
            command: "pwd",
            applying: .currentDirectoryURL(directoryURL),
            .standardStreamMirroring(.disabled)
        )

        #expect(record.commandLine == "pwd")
        #expect(record.stdoutString == directoryURL.path)
    }

    @Test("AnyCommandLineTool records successful raw command execution attempts")
    func anyCommandLineToolRecordsSuccessfulRawCommandExecutionAttempts() async throws {
        let tool = LegacyAnyCommandLineToolCompatibilityTool()
        let record = try await tool._run(
            command: "printf attempt-record",
            applying: .standardStreamMirroring(.disabled)
        )
        let attempts = await tool._internalState._executionAttempts
        let attempt = try #require(attempts.first)

        #expect(attempts.count == 1)
        #expect(attempt.shellScopeID != nil)
        #expect(attempt.source.commandLine == record.commandLine)
        #expect(attempt.finishedAt >= attempt.startedAt)

        switch attempt.result {
            case .success(let recorded):
                #expect(recorded.commandLine == "printf attempt-record")
                #expect(recorded.stdoutString == "attempt-record")
            case .failure(let error):
                Issue.record("Expected a successful execution attempt, got \(String(reflecting: error)).")
        }
    }

    @Test("AnyCommandLineTool records failed raw command execution attempts")
    func anyCommandLineToolRecordsFailedRawCommandExecutionAttempts() async throws {
        let tool = LegacyAnyCommandLineToolCompatibilityTool()

        do {
            _ = try await tool._run(
                command: "printf should-not-run",
                applying: [
                    .standardStreamMirroring(.disabled),
                    .standardStreamMirroring(.terminal)
                ]
            )
            Issue.record("Expected conflicting configuration differences to throw.")
        } catch {
            let attempts = await tool._internalState._executionAttempts
            let attempt = try #require(attempts.first)

            #expect(attempts.count == 1)
            #expect(attempt.shellScopeID != nil)
            #expect(attempt.source.commandLine == "printf should-not-run")
            #expect(attempt.finishedAt >= attempt.startedAt)

            switch attempt.result {
                case .success(let record):
                    Issue.record("Expected a failed execution attempt, got \(record.debugDescription).")
                case .failure:
                    break
            }
        }
    }

    @Test("Borrowed SystemShell rejects owned process teardown")
    func borrowedSystemShellRejectsOwnedProcessTeardown() async throws {
        do {
            try await LegacyAnyCommandLineToolCompatibilityTool().withUnsafeSystemShell { shell in
                try await shell.teardownRunningProcesses()
            }

            Issue.record("Expected borrowed SystemShell teardown to fail.")
        } catch SystemShell._DeveloperError.borrowedShellOwnedOperation(let operation) {
            #expect(operation == .teardownRunningProcesses)
        } catch {
            Issue.record("Expected borrowedShellOwnedOperation, got \(error).")
            #expect(
                String(describing: error).contains("withUnsafeSystemShell"),
                "The teardown failure should call out the borrowed-shell API boundary."
            )
        }
    }

    @Test("Borrowed SystemShell kill is an owned operation")
    func borrowedSystemShellKillIsAnOwnedOperation() async throws {
        do {
            try await LegacyAnyCommandLineToolCompatibilityTool().withUnsafeSystemShell { shell in
                try shell._validateCanAttemptOwnedShellOperation(.kill)
            }

            Issue.record("Expected borrowed SystemShell kill ownership check to fail.")
        } catch SystemShell._DeveloperError.borrowedShellOwnedOperation(let operation) {
            #expect(operation == .kill)
        } catch {
            Issue.record("Expected borrowedShellOwnedOperation, got \(error).")
            #expect(
                String(describing: error).contains("withUnsafeSystemShell"),
                "The kill ownership failure should call out the borrowed-shell API boundary."
            )
        }
    }

    @Test("Borrowed SystemShell rejects use after withUnsafeSystemShell returns")
    func borrowedSystemShellRejectsUseAfterClosureReturns() async throws {
        var escapedShell: SystemShell?

        try await LegacyAnyCommandLineToolCompatibilityTool().withUnsafeSystemShell { shell in
            escapedShell = shell
        }

        do {
            _ = try await escapedShell?.run(command: "echo leaked")

            Issue.record("Expected escaped borrowed SystemShell use to fail.")
        } catch SystemShell._DeveloperError.invalidBorrowedShellLease {
        } catch {
            Issue.record("Expected invalidBorrowedShellLease, got \(error).")
        }
    }

    @Test("Legacy sink wrapper uses scoped SystemShell configuration")
    func legacySinkWrapperUsesScopedConfiguration() async throws {
        let result = try await LegacyAnyCommandLineToolCompatibilityTool().withUnsafeSystemShell(sink: .null) { shell in
            try await shell.run(command: "echo captured")
        }

        #expect(
            result.stdoutString == "captured",
            "The legacy .null sink should disable mirroring while preserving captured stdout."
        )
    }

    @Test("AnyCommandLineTool tracks borrowed shell scopes")
    func anyCommandLineToolTracksBorrowedShellScopes() async throws {
        let tool = LegacyAnyCommandLineToolCompatibilityTool()
        var shellState: SystemShell._InternalState?

        try await tool.withUnsafeSystemShell { shell in
            shellState = shell._internalState

            let toolScope = try #require(
                await tool._internalState._activeShellScopes.first,
                "The command-line tool should track the active borrowed shell scope."
            )
            let shellScope = try #require(
                await shell._internalState._activeShellScopes.first,
                "The borrowed shell state should track its active root scope."
            )

            #expect(toolScope.id == shellScope.id)
            #expect(toolScope.kind == .commandLineToolLease)
            #expect(toolScope.parentID == nil)
            #expect(toolScope.rootID == toolScope.id)

            try await shell.withConfiguration(
                applying: SystemShell.Configuration.Difference.standardStreamMirroring(.disabled)
            ) { childShell in
                let childScopeID = try #require(
                    childShell._shellScopeID,
                    "A child shell derived from the borrowed root should have a scope ID."
                )
                let childScope = try #require(
                    await shell._internalState._shellScope(id: childScopeID),
                    "The shell state should track child configuration scopes."
                )

                #expect(childScope.kind == .configurationScope)
                #expect(childScope.parentID == shellScope.id)
                #expect(childScope.rootID == shellScope.id)
                #expect(childScope.status == .active)
            }

            let completedChildren = await shell._internalState._completedShellScopes.filter {
                $0.kind == .configurationScope && $0.parentID == shellScope.id
            }

            #expect(
                completedChildren.count == 1,
                "Configuration child scopes should be completed when the scoped operation returns."
            )
        }

        #expect(await tool._internalState._activeShellScopes.isEmpty)

        let completedToolScope = try #require(
            await tool._internalState._completedShellScopes.first,
            "The command-line tool should retain completed borrowed shell scope history."
        )
        let completedShellScope = try #require(
            await shellState?._completedShellScopes.first,
            "The shell state should retain completed root scope history."
        )

        #expect(completedToolScope.id == completedShellScope.id)
        #expect(completedToolScope.status == .completed)
    }

    @Test("AnyCommandLineTool shell scope tracking is observable")
    func anyCommandLineToolShellScopeTrackingIsObservable() async throws {
        let tool = LegacyAnyCommandLineToolCompatibilityTool()
        var cancellable: AnyCancellable?

        await withCheckedContinuation { continuation in
            cancellable = tool.objectDidChange.prefix(1).sink {
                continuation.resume()
            }

            Task {
                try await tool.withUnsafeSystemShell { _ in

                }
            }
        }

        withExtendedLifetime(cancellable) {}
        #expect(
            await !tool._internalState._shellScopes.isEmpty,
            "Observing the command-line tool should not require polling shell state."
        )
    }

    @Test("Killing an AnyCommandLineTool with no active shells makes the instance unusable")
    func killingAnyCommandLineToolWithNoActiveShellsMakesInstanceUnusable() async throws {
        let tool = LegacyAnyCommandLineToolCompatibilityTool()

        try await tool.kill()

        #expect(await tool._internalState._lifecycleStatus == .killed)

        do {
            try await tool.withUnsafeSystemShell { _ in

            }

            Issue.record("Expected killed AnyCommandLineTool instance usage to fail.")
        } catch AnyCommandLineTool._DeveloperError.killedInstanceUsage {
        } catch {
            Issue.record("Expected killedInstanceUsage, got \(error).")
        }
    }

    @Test("Killing an AnyCommandLineTool tears down active borrowed shell sessions")
    func killingAnyCommandLineToolTearsDownActiveBorrowedShellSessions() async throws {
        let tool = LegacyAnyCommandLineToolCompatibilityTool()
        var shellState: SystemShell._InternalState?

        let task = Task {
            try await tool.withUnsafeSystemShell { shell in
                shellState = shell._internalState

                _ = try await shell.run(command: "trap 'exit 0' TERM; while true; do sleep 1; done")
            }
        }

        while await tool._internalState._activeShellSessions.isEmpty {
            try await Task.sleep(.milliseconds(10))
        }

        while await shellState?.runningProcesses.isEmpty != false {
            try await Task.sleep(.milliseconds(10))
        }

        try await tool.kill()

        _ = try await task.value

        #expect(await tool._internalState._lifecycleStatus == .killed)
        #expect(await tool._internalState._activeShellScopes.isEmpty)
        #expect(await shellState?.runningProcesses.isEmpty == true)

        let completedScope = try #require(
            await tool._internalState._completedShellScopes.first,
            "The killed command-line tool should complete its active shell scope."
        )

        #expect(completedScope.status == .completed)
    }
}

#endif
