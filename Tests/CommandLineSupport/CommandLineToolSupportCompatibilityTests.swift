#if os(macOS)

import CommandLineToolSupport
import Combine
import Foundation
import Merge
import Testing

final class CompatibilityRootTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "root"
    }

    @Flag(name: "verbose", placement: .selectedCommand)
    var verbose: Bool = false

    @Flag(name: "force", placement: .finalCommand)
    var force: Bool = false

    @Parameter(name: nil, placement: .finalCommand)
    var path: String? = nil

    @Subcommand(of: CompatibilityRootTool.self, name: "leaf", command: CompatibilityLeafTool())
    var leaf
}

final class CompatibilityLeafTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "leaf"
    }
}

final class EchoCompatibilityTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "echo"
    }

    @Parameter(name: nil)
    var text: String? = nil

    @Subcommand(of: EchoCompatibilityTool.self, name: "nested", command: EchoNestedCompatibilityTool())
    var nested
}

final class EchoNestedCompatibilityTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "nested"
    }
}

final class TrueCompatibilityTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "true"
    }
}

final class OptionalParameterTool: AnyCommandLineTool, CommandLineTool {
    @Parameter
    var value: Any?

    override init() {

    }
}

final class DefaultValueParameterTool: AnyCommandLineTool, CommandLineTool {
    enum Mode: Hashable {
        case disabled
    }

    @Parameter
    var mode: Mode = .disabled

    @Parameter
    var values: [String] = []
}

final class SummaryModeTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "swiftc"
    }

    override var keyConversion: _CommandLineToolOptionKeyConversion? {
        .hyphenPrefixed
    }

    @Flag
    var mode: Mode? = nil

    @Parameter(name: "target")
    var target: String? = nil

    @Parameter(name: "module-name")
    var moduleName: String? = nil

    @Parameter(name: nil)
    var inputFiles: [String] = []

    @Parameter(name: "emit-loaded-module-trace-path")
    var emitLoadedModuleTracePath: EmitLoadedModuleTracePath? = nil

    var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        \.$target
        \.$mode

        Switch(\.$emitLoadedModuleTracePath) {
            DefaultCase {
                ""
            }
            Case(.stdout) {
                "-emit-loaded-module-trace"
                \.$emitLoadedModuleTracePath
            }
        }
    }
}

extension SummaryModeTool {
    enum Mode: String, CaseIterable, Sendable, CLT.OptionKeyConvertible {
        var name: String {
            rawValue
        }

        var conversion: _CommandLineToolOptionKeyConversion {
            .hyphenPrefixed
        }

        case typecheck
    }

    enum EmitLoadedModuleTracePath: Hashable, CLT.ArgumentValueConvertible {
        case file(String)
        case stdout

        var argumentValue: String {
            switch self {
                case .file(let path):
                    path
                case .stdout:
                    "-"
            }
        }
    }
}

final class ConditionalSummaryTool: AnyCommandLineTool, CommandLineTool {
    @Parameter(name: "output")
    var output: String? = nil

    @Flag(name: "verbose")
    var verbose: Bool = false

    var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        When(\.$output, .hasValue) {
            "write"
            \.$output
        } else: {
            "dry-run"
        }

        \.$verbose
    }
}

final class SelectingToolFixture: AnyCommandLineToolWithSelectedTool, CommandLineTool {
    override var _commandName: String {
        "selectingtool"
    }
}

@_CommandLineToolModel
final class MacroBackedCompatibilityTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "macro-backed"
    }
}

@Suite
struct CommandLineToolSupportCompatibilityTests {
    @Test
    func placementAliasesPreserveArgumentPositionBehavior() throws {
        let command = try CompatibilityRootTool()
            .with(\.verbose, true)
            .with(\.force, true)
            .with(\.path, "Sources")
            .leaf
            .invocation

        #expect(command == "root leaf --verbose --force Sources")
    }

    @Test
    func subcommandsCanBeSelectedWithCallSyntax() throws {
        let command = ExampleXcrunTool()
            .simctl()
            .io()

        #expect(try command.invocation == "xcrun simctl io")
    }

    @Test
    func selectedToolSemanticsDefaultToStaticExplicitArgument() {
        let semantics = SelectingToolFixture().toolSelectionSemantics

        #expect(semantics.phase == .beforeInvocation)
        #expect(semantics.mutability == .fixedOnceSelected)
        #expect(semantics.disclosure == .explicitArgument)
        #expect(semantics.argumentBoundary == .selectedToolConsumesRemainingArguments)
    }

    @Test
    func commandLineToolModelMacroSynthesizesProvisionalResultAliases() {
        let rawResultType: MacroBackedCompatibilityTool._RawRunResult.Type = Process.RunResult.self
        let executionRecordType: MacroBackedCompatibilityTool._ExecutionRecord.Type = _CommandLineToolExecutionRecord<MacroBackedCompatibilityTool>.self

        #expect(rawResultType == Process.RunResult.self)
        #expect(executionRecordType == _CommandLineToolExecutionRecord<MacroBackedCompatibilityTool>.self)
    }

    @Test
    func structuredInvocationPreservesStringInvocation() throws {
        let command = CompatibilityRootTool()
            .with(\.force, true)
            .with(\.path, "Sources")

        let invocation = try command.commandInvocation

        #expect(invocation.components == ["root", "--force", "Sources"])
        #expect(invocation.commandName == "root")
        #expect(invocation.arguments == ["--force", "Sources"])
        #expect(invocation.commandLine == (try command.invocation))
        #expect(String(describing: invocation) == (try command.invocation))
    }

    @Test
    func oldPositionNamesRemainEquivalent() {
        #expect(CommandLineToolArgumentPlacement.declaringCommand == .local)
        #expect(CommandLineToolArgumentPlacement.selectedCommand == .nextCommand)
        #expect(CommandLineToolArgumentPlacement.finalCommand == .lastCommand)
    }

    @Test
    func optionalNonEquatableParametersCanBeModeled() throws {
        #expect(try OptionalParameterTool().invocation == "optionalparametertool")
    }

    @Test("CommandLineTool callAsFunction still returns Process.RunResult")
    func commandLineToolCallAsFunctionStillReturnsRawProcessRunResult() async throws {
        let result: Process.RunResult = try await TrueCompatibilityTool().callAsFunction()

        #expect(result.stdoutString == nil)
    }

    @Test("CommandLineTool _run records modeled invocations")
    func commandLineToolRunRecordsModeledInvocation() async throws {
        let tool = EchoCompatibilityTool()
            .with(\.text, "modeled-record")
        let record = try await tool._run(applying: .standardStreamMirroring(.disabled))

        guard case .modeledInvocation(let invocation) = record.source else {
            Issue.record("Expected CommandLineTool._run() to record a modeled invocation.")
            return
        }

        #expect(record.tool === tool)
        #expect(invocation.commandLine == "echo modeled-record")
        #expect(record.invocation == invocation)
        #expect(record.commandLine == invocation.commandLine)
        #expect(record.stdoutString == "modeled-record")
        #expect(try record.toString() == "modeled-record")
    }

    @Test("GenericSubcommand _run records the full modeled chain")
    func genericSubcommandRunRecordsFullModeledChain() async throws {
        let command = EchoCompatibilityTool().nested
        let record = try await command._run(applying: .standardStreamMirroring(.disabled))

        guard case .modeledInvocation(let invocation) = record.source else {
            Issue.record("Expected GenericSubcommand._run() to record a modeled invocation.")
            return
        }

        #expect(invocation.commandLine == "echo nested")
        #expect(record.commandLine == "echo nested")
        #expect(record.stdoutString == "nested")
    }

    @Test("AnyCommandLineTool _run(command:) records shell command lines")
    func anyCommandLineToolRunCommandRecordsShellCommandLine() async throws {
        let tool = CompatibilityLeafTool()
        let record = try await tool._run(
            command: "printf raw-shell",
            applying: .standardStreamMirroring(.disabled)
        )

        guard case .shellCommandLine(let commandLine) = record.source else {
            Issue.record("Expected AnyCommandLineTool._run(command:) to record a shell command line.")
            return
        }

        #expect(commandLine == "printf raw-shell")
        #expect(record.invocation == nil)
        #expect(record.commandLine == commandLine)
        #expect(record.stdoutString == "raw-shell")
    }

    @Test("Command-line tool _run applies scoped SystemShell configuration")
    func commandLineToolRunAppliesScopedSystemShellConfiguration() async throws {
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

        let record = try await CompatibilityLeafTool()._run(
            command: "pwd",
            applying: .currentDirectoryURL(directoryURL),
            .standardStreamMirroring(.disabled)
        )

        #expect(record.commandLine == "pwd")
        #expect(record.stdoutString == directoryURL.path)
    }

    @Test
    func defaultValueParametersDoNotRequireArgumentValueConvertible() {
        let tool = DefaultValueParameterTool()

        #expect(tool.mode == .disabled)
        #expect(tool.values == [])
    }

    @Test
    func invocationSummaryCanModelModeSpecificArguments() throws {
        let command = try SummaryModeTool()
            .with(\.target, "arm64-apple-macos")
            .with(\.mode, .typecheck)
            .with(\.emitLoadedModuleTracePath, .stdout)
            .with(\.moduleName, "Dummy")
            .with(\.inputFiles, ["main.swift"])
            .invocation

        #expect(
            command == "swiftc -target arm64-apple-macos -typecheck -emit-loaded-module-trace -emit-loaded-module-trace-path - -module-name Dummy main.swift"
        )
    }

    @Test
    func invocationSummaryCanConditionallyRenderArguments() throws {
        let writeCommand = try ConditionalSummaryTool()
            .with(\.output, "trace.json")
            .with(\.verbose, true)
            .invocation

        let dryRunCommand = try ConditionalSummaryTool()
            .with(\.verbose, true)
            .invocation

        #expect(writeCommand == "conditionalsummarytool write --output trace.json --verbose")
        #expect(dryRunCommand == "conditionalsummarytool dry-run --verbose")
    }

    @Test("Borrowed SystemShell rejects owned process teardown")
    func borrowedSystemShellRejectsOwnedProcessTeardown() async throws {
        do {
            try await CompatibilityLeafTool().withUnsafeSystemShell { shell in
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
            try await CompatibilityLeafTool().withUnsafeSystemShell { shell in
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

        try await CompatibilityLeafTool().withUnsafeSystemShell { shell in
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
        let result = try await CompatibilityLeafTool().withUnsafeSystemShell(sink: .null) { shell in
            try await shell.run(command: "echo captured")
        }

        #expect(
            result.stdoutString == "captured",
            "The legacy .null sink should disable mirroring while preserving captured stdout."
        )
    }

    @Test("Command-line tools track borrowed shell scopes")
    func commandLineToolsTrackBorrowedShellScopes() async throws {
        let tool = CompatibilityLeafTool()
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

    @Test("Command-line tool shell scope tracking is observable")
    func commandLineToolShellScopeTrackingIsObservable() async throws {
        let tool = CompatibilityLeafTool()
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

    @Test("Killing a command-line tool with no active shells makes the instance unusable")
    func killingCommandLineToolWithNoActiveShellsMakesInstanceUnusable() async throws {
        let tool = CompatibilityLeafTool()

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

    @Test("Killing a command-line tool tears down active borrowed shell sessions")
    func killingCommandLineToolTearsDownActiveBorrowedShellSessions() async throws {
        let tool = CompatibilityLeafTool()
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
