#if os(macOS)

import CommandLineToolSupport
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

final class OptionalParameterTool: AnyCommandLineTool, CommandLineTool {
    @Parameter
    var value: Any?

    override init() {

    }
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

    @Test
    func borrowedSystemShellRejectsProcessTeardown() async throws {
        do {
            try await CompatibilityLeafTool().withUnsafeSystemShell { shell in
                try await shell.teardownRunningProcesses()
            }

            Issue.record("Expected borrowed SystemShell teardown to fail")
        } catch {
            #expect(String(describing: error).contains("AnyCommandLineTool.withUnsafeSystemShell"))
        }
    }
}

#endif
