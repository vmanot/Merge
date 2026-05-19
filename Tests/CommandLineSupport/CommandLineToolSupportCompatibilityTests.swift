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

final class RawCommandCompatibilityTool: AnyCommandLineTool {

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
            Case(value: .stdout) {
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
        When(\.$output, .isPresent) {
            "write"
            \.$output
        } else: {
            "dry-run"
        }

        \.$verbose
    }
}

final class ParentReferencedSummaryTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "parent-summary"
    }

    @Parameter(name: "sdk")
    var sdk: String? = nil

    @Subcommand(of: ParentReferencedSummaryTool.self, name: "compile", command: Compile())
    var compile

    final class Compile: AnyCommandLineTool, CommandLineTool, _Subcommand {
        typealias ParentCommand = ParentReferencedSummaryTool

        @Parameter(name: nil)
        var input: String? = nil

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            self.$sdk

            When(self.$sdk, equals: "macosx") {
                "--sdk-forwarded"
            }

            \.$input
        }
    }
}

final class ExactConditionalSummaryTool: AnyCommandLineTool, CommandLineTool {
    @Parameter(name: "format")
    var format: String? = nil

    var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        When(\.$format, equals: "json") {
            "--json"
        } else: {
            "--text"
        }
    }
}

final class ResolvedDescriptionTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "resolved-description"
    }

    @Parameter(name: "target")
    var target: String? = nil

    @Parameter(name: nil)
    var inputs: [String] = []

    @Flag(name: "v")
    var verbosity: Int = 0

    @Flag(name: "trace")
    var trace: Bool = false
}

final class URLParameterCompatibilityTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "url-parameter"
    }

    @Parameter(name: "C")
    var checkoutURL: URL? = nil
}

final class ConstructorBackedFlagTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "constructor-flag"
    }

    @Flag(name: "disable-colored-output")
    var disableColoredOutput: Bool = false

    init(disableColoredOutput: Bool = false) {
        self._disableColoredOutput = Flag(
            wrappedValue: disableColoredOutput,
            defaultValue: false,
            name: "disable-colored-output"
        )

        super.init()
    }
}

final class SelectingToolFixture: AnyCommandLineToolWithSelectedTool, CommandLineTool {
    override var _commandName: String {
        "selectingtool"
    }
}

final class PrintfSelectingTool: AnyCommandLineToolWithSelectedTool, CommandLineTool {
    override var _commandName: String {
        "printf"
    }

    @SelectedTool(of: PrintfSelectingTool.self, name: "selected-tool", tool: SelectedPrintfPayloadTool())
    var payload
}

final class SelectedPrintfPayloadTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "underlying-selected-tool"
    }
}

final class SelectedPrintfPayloadWithSubcommandTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "underlying-selected-parent"
    }

    @Flag(name: "verbose")
    var verbose: Bool = false

    @Subcommand(of: SelectedPrintfPayloadWithSubcommandTool.self, name: "child", command: Child())
    var child

    final class Child: AnyCommandLineTool, CommandLineTool {
        override var _commandName: String {
            "child"
        }
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
    func xcrunKnownSelectedToolRendersIndependentSwiftCompiler() throws {
        let command = ExampleXcrunTool()
            .with(\.sdk, "macosx")
            .swiftc()
            .with(\.typecheck, true)
            .with(\.inputFiles, ["Foo.swift"])

        #expect(try command.invocation == "xcrun -sdk macosx swiftc -typecheck Foo.swift")
    }

    @Test
    func xcrunCanSelectExternallyModeledSwiftCompiler() throws {
        let command = ExampleXcrunTool()
            .with(\.sdk, "macosx")
            .selecting(ExampleSwiftCompilerTool())
            .with(\.typecheck, true)
            .with(\.inputFiles, ["Foo.swift"])

        #expect(try command.invocation == "xcrun -sdk macosx swiftc -typecheck Foo.swift")
    }

    @Test
    func xcrunCanSelectExternallyModeledToolWithItsOwnSubcommands() throws {
        let command = ExampleXcrunTool()
            .selecting(ExampleSimulatorControlTool())
            .with(\.verbose, true)
            .io()

        #expect(try command.invocation == "xcrun simctl --verbose io")
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
    func selectedToolProtocolExposesTypedSelectingAndSelectedTools() {
        let selectingTool = SelectingToolFixture()
        let selectedTool = CompatibilityLeafTool()
        let tool: GenericSelectedCommandLineTool<SelectingToolFixture, CompatibilityLeafTool> = selectingTool.selecting(selectedTool)

        #expect(tool.selectingTool === selectingTool)
        #expect(tool.selectedTool === selectedTool)
        #expect(tool._commandName == "leaf")
        #expect(tool.toolSelectionSemantics == .staticExplicitArgument)
        #expect(tool.description == "selectingtool selecting leaf")
        #expect(tool.debugDescription.contains("GenericSelectedCommandLineTool"))
    }

    @Test
    func resolvingAndInvokingSelectedToolProtocolHasDefaultResolutionSemantics() {
        let tool = SelectingToolFixture().selecting(CompatibilityLeafTool())
        let semantics = tool.selectedToolResolutionSemantics

        #expect(semantics.phase == .beforeInvocation)
        #expect(semantics.invocation == .throughSelectingTool)
        #expect(semantics.executableDisclosure == .selectedToolName)
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

        #expect(invocation.components == [
            CommandLineToolInvocation.Argument("root"),
            CommandLineToolInvocation.Argument("--force"),
            CommandLineToolInvocation.Argument("Sources")
        ])
        #expect(invocation.rawComponents == ["root", "--force", "Sources"])
        #expect(invocation.commandName == "root")
        #expect(invocation.arguments.map(\.rawValue) == ["--force", "Sources"])
        #expect(invocation.commandLine == (try command.invocation))
        #expect(invocation.posixShellCommandLine == "'root' '--force' 'Sources'")
        #expect(String(describing: invocation) == (try command.invocation))
    }

    @Test
    func urlParametersRenderSemanticValuesBeforeShellEscaping() throws {
        let url = URL(fileURLWithPath: "/tmp/path with spaces")
        let invocation = try URLParameterCompatibilityTool()
            .with(\.checkoutURL, url)
            .commandInvocation

        #expect(url.argumentValue == "/tmp/path with spaces")
        #expect(invocation.rawComponents == ["url-parameter", "-C", "/tmp/path with spaces"])
        #expect(invocation.commandLine == "url-parameter -C /tmp/path with spaces")
        #expect(invocation.posixShellCommandLine == "'url-parameter' '-C' '/tmp/path with spaces'")
    }

    @Test
    func structuredInvocationHasUsefulDebugReflection() throws {
        let invocation = try CompatibilityRootTool()
            .with(\.force, true)
            .with(\.path, "Sources")
            .commandInvocation
        let argument = try #require(invocation.arguments.first)
        let mirrorLabels = Array(Mirror(reflecting: invocation).children).map(\.label)
        let argumentMirrorLabels = Array(Mirror(reflecting: argument).children).map(\.label)

        #expect(invocation.description == "root --force Sources")
        #expect(invocation.debugDescription == "CommandLineToolInvocation(\"root --force Sources\")")
        #expect(mirrorLabels == ["components", "rawComponents", "commandName", "arguments", "commandLine"])
        #expect(argument.description == "--force")
        #expect(argument.posixShellEscapedValue == "'--force'")
        #expect(argument.debugDescription == "CommandLineToolInvocation.Argument(.string(\"--force\"))")
        #expect(argumentMirrorLabels == ["storage", "stringValue", "rawValue", "rawBytes"])
    }

    @Test
    func structuredInvocationArgumentReflectsRawBytes() throws {
        let argument = CommandLineToolInvocation.Argument(rawBytes: [0xff])
        let emptyArgument = CommandLineToolInvocation.Argument("")
        let quotedArgument = CommandLineToolInvocation.Argument("it's here")
        let mirrorLabels = Array(Mirror(reflecting: argument).children).map(\.label)

        #expect(argument.storage == .rawBytes([0xff]))
        #expect(argument.stringValue == nil)
        #expect(argument.rawBytes == [0xff])
        #expect(emptyArgument.posixShellEscapedValue == "''")
        #expect(quotedArgument.posixShellEscapedValue == "'it'\\''s here'")
        #expect(argument.debugDescription == "CommandLineToolInvocation.Argument(.rawBytes([255]))")
        #expect(mirrorLabels == ["storage", "stringValue", "rawValue", "rawBytes"])
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
        #expect(record.description == "echo modeled-record")
        #expect(record.debugDescription.contains("EchoCompatibilityTool"))
        #expect(record.source.description == "echo modeled-record")
        #expect(record.source.debugDescription.contains("modeledInvocation"))
        #expect(Array(Mirror(reflecting: record).children).map(\.label) == ["tool", "source", "processResult", "selectedToolInvocation", "commandLine"])
        #expect(Array(Mirror(reflecting: record.source).children).map(\.label) == ["case", "invocation", "commandLine"])
    }

    @Test("Invocation arguments compose with modeled root invocations")
    func invocationArgumentsComposeWithModeledRootInvocations() throws {
        let arguments: CommandLineToolInvocation.Arguments = ["status", "--porcelain"]
        let invocation = try CompatibilityRootTool()
            .with(\.force, true)
            .with(\.path, "Sources")
            ._invocation(appending: arguments)

        #expect(arguments.rawValues == ["status", "--porcelain"])
        #expect(arguments.description == "status --porcelain")
        #expect(arguments.debugDescription == "CommandLineToolInvocation.Arguments([\"status\", \"--porcelain\"])")
        #expect(invocation.rawComponents == ["root", "--force", "Sources", "status", "--porcelain"])
        #expect(invocation.arguments.map(\.rawValue) == ["--force", "Sources", "status", "--porcelain"])
        #expect(Array(Mirror(reflecting: arguments).children).map(\.label) == ["elements", "rawValues"])
    }

    @Test("Invocation arguments preserve empty argv elements at the model layer")
    func invocationArgumentsPreserveEmptyArgvElementsAtModelLayer() throws {
        let arguments: CommandLineToolInvocation.Arguments = ["status", "", "--porcelain"]
        let invocation = try CompatibilityRootTool()
            ._invocation(appending: arguments)

        #expect(arguments.rawValues == ["status", "", "--porcelain"])
        #expect(invocation.rawComponents == ["root", "status", "", "--porcelain"])
        #expect(invocation.arguments.map(\.rawValue) == ["status", "", "--porcelain"])
    }

    @Test("CommandLineTool _run can execute structured invocation arguments")
    func commandLineToolRunExecutesStructuredInvocationArguments() async throws {
        let tool = EchoCompatibilityTool()
        let record = try await tool._run(
            appending: ["arguments-record"],
            applying: .standardStreamMirroring(.disabled)
        )

        guard case .modeledInvocation(let invocation) = record.source else {
            Issue.record("Expected invocation-arguments _run to preserve modeled invocation source metadata.")
            return
        }

        #expect(record.tool === tool)
        #expect(invocation.commandLine == "echo arguments-record")
        #expect(invocation.arguments.map(\.rawValue) == ["arguments-record"])
        #expect(record.commandLine == "echo arguments-record")
        #expect(record.stdoutString == "arguments-record")
    }

    @Test("CommandLineTool _runCollectingOutput captures output without terminal mirroring")
    func commandLineToolRunCollectingOutputCapturesOutput() async throws {
        let tool = EchoCompatibilityTool()
        let record = try await tool._runCollectingOutput(appending: ["collected-record"])

        guard case .modeledInvocation(let invocation) = record.source else {
            Issue.record("Expected _runCollectingOutput to preserve modeled invocation source metadata.")
            return
        }

        #expect(record.tool === tool)
        #expect(invocation.commandLine == "echo collected-record")
        #expect(record.stdoutString == "collected-record")
    }

    @Test("CommandLineTool _run can execute explicitly constructed invocations")
    func commandLineToolRunExecutesExplicitInvocations() async throws {
        let tool = EchoCompatibilityTool()
        let invocation = CommandLineToolInvocation(
            components: [
                CommandLineToolInvocation.Argument("echo"),
                CommandLineToolInvocation.Argument("explicit invocation")
            ]
        )
        let record = try await tool._run(
            invocation: invocation,
            applying: .standardStreamMirroring(.disabled)
        )

        guard case .modeledInvocation(let recordedInvocation) = record.source else {
            Issue.record("Expected explicit invocation _run to preserve modeled invocation source metadata.")
            return
        }

        #expect(record.tool === tool)
        #expect(recordedInvocation == invocation)
        #expect(record.commandLine == "echo explicit invocation")
        #expect(record.stdoutString == "explicit invocation")
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
        #expect(record.selectedToolInvocation == nil)
    }

    @Test("Coupled and decoupled selected-tool execution records expose equivalent metadata")
    func coupledAndDecoupledSelectionProduceEquivalentMetadata() async throws {
        let coupled = try await PrintfSelectingTool()
            .payload()
            ._run(applying: .standardStreamMirroring(.disabled))
        let decoupled = try await PrintfSelectingTool()
            .selecting(SelectedPrintfPayloadTool(), name: "selected-tool")
            ._run(applying: .standardStreamMirroring(.disabled))

        #expect(coupled.commandLine == "printf selected-tool")
        #expect(decoupled.commandLine == "printf selected-tool")
        #expect(coupled.tool.selectedTool._commandName == "underlying-selected-tool")
        #expect(decoupled.tool.selectedTool._commandName == "underlying-selected-tool")
        #expect(coupled.tool.selectedToolCommandName == "selected-tool")
        #expect(decoupled.tool.selectedToolCommandName == "selected-tool")
        #expect(coupled.stdoutString == "selected-tool")
        #expect(decoupled.stdoutString == "selected-tool")
        #expect(coupled.selectedToolInvocation?.selectingToolCommandName == "printf")
        #expect(decoupled.selectedToolInvocation?.selectingToolCommandName == "printf")
        #expect(coupled.selectedToolInvocation?.selectedToolCommandName == "selected-tool")
        #expect(decoupled.selectedToolInvocation?.selectedToolCommandName == "selected-tool")
        #expect(coupled.selectedToolInvocation?.selectedToolCommandPath == ["selected-tool"])
        #expect(coupled.selectedToolInvocation?.selectedToolCommandPath == decoupled.selectedToolInvocation?.selectedToolCommandPath)
        #expect(coupled.selectedToolInvocation?.commandLine == coupled.commandLine)

        let selectedToolInvocation = try #require(coupled.selectedToolInvocation)

        #expect(selectedToolInvocation.description == "printf selected-tool")
        #expect(selectedToolInvocation.debugDescription.contains("selectedToolCommandName: \"selected-tool\""))
        #expect(Array(Mirror(reflecting: selectedToolInvocation).children).map(\.label) == [
            "renderedInvocation",
            "selectingToolCommandName",
            "selectedToolCommandName",
            "selectedToolCommandPath",
            "selectionSemantics",
            "resolutionSemantics",
            "commandLine"
        ])
    }

    @Test("Selected-tool subcommands preserve selected-tool-local arguments and metadata")
    func selectedToolSubcommandsPreserveSelectedToolLocalArgumentsAndMetadata() async throws {
        let record = try await PrintfSelectingTool()
            .selecting(SelectedPrintfPayloadWithSubcommandTool(), name: "selected-parent")
            .with(\.verbose, true)
            .child()
            ._run(applying: .standardStreamMirroring(.disabled))

        #expect(record.commandLine == "printf selected-parent --verbose child")
        #expect(record.stdoutString == "selected-parent")
        #expect(record.isSelectedToolInvocation)
        #expect(record.selectedToolInvocation?.selectingToolCommandName == "printf")
        #expect(record.selectedToolInvocation?.selectedToolCommandName == "selected-parent")
        #expect(record.selectedToolInvocation?.selectedToolCommandPath == ["selected-parent", "child"])
        #expect(record.selectedToolInvocation?.commandLine == record.commandLine)
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

    @Test("AnyCommandLineTool _run(command:) is available without modeled CommandLineTool conformance")
    func anyCommandLineToolRunCommandDoesNotRequireCommandLineToolConformance() async throws {
        let tool = RawCommandCompatibilityTool()
        let record = try await tool._run(
            command: "printf raw-base",
            applying: .standardStreamMirroring(.disabled)
        )

        #expect(record.tool === tool)
        #expect(record.commandLine == "printf raw-base")
        #expect(record.stdoutString == "raw-base")
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

    @Test
    func invocationSummaryCanUseReadableEqualityConditions() throws {
        let jsonCommand = try ExactConditionalSummaryTool()
            .with(\.format, "json")
            .invocation

        let textCommand = try ExactConditionalSummaryTool()
            .with(\.format, "text")
            .invocation

        #expect(jsonCommand == "exactconditionalsummarytool --json --format json")
        #expect(textCommand == "exactconditionalsummarytool --text --format text")
    }

    @Test
    func resolvedDescriptionPreservesInvocationArgumentComponents() throws {
        let description = try ResolvedDescriptionTool()
            .with(\.target, "arm64-apple-macosx15.0")
            .with(\.inputs, ["Sources/main.swift", "Sources/support.swift"])
            .with(\.verbosity, 3)
            .with(\.trace, true)
            .resolve()

        let target = try #require(description.arguments[id: .init(rawValue: "target", commandName: "resolved-description")])
        let inputs = try #require(description.arguments[id: .init(rawValue: "inputs", commandName: "resolved-description")])
        let verbosity = try #require(description.arguments[id: .init(rawValue: "verbosity", commandName: "resolved-description")])
        let trace = try #require(description.arguments[id: .init(rawValue: "trace", commandName: "resolved-description")])

        #expect(target.invocationArguments == ["--target", "arm64-apple-macosx15.0"])
        #expect(target.invocationComponents == [
            .option(
                key: CommandLineToolInvocation.Argument("--target"),
                separator: .space,
                values: [CommandLineToolInvocation.Argument("arm64-apple-macosx15.0")]
            )
        ])
        #expect(inputs.invocationArguments == ["Sources/main.swift", "Sources/support.swift"])
        #expect(inputs.invocationComponents.map(\.kind) == [.positionalArgument, .positionalArgument])
        #expect(inputs.invocationArgumentValues == [
            CommandLineToolInvocation.Argument("Sources/main.swift"),
            CommandLineToolInvocation.Argument("Sources/support.swift")
        ])
        #expect(inputs.invocationArgument == "Sources/main.swift Sources/support.swift")
        #expect(verbosity.invocationArguments == ["-vvv"])
        #expect(verbosity.invocationArgumentValues == [CommandLineToolInvocation.Argument("-vvv")])
        #expect(trace.invocationArguments == ["--trace"])
        #expect(trace.invocationArgumentValues == [CommandLineToolInvocation.Argument("--trace")])
    }

    @Test
    func resolvedDescriptionHasUsefulDebugReflection() throws {
        let description = try ResolvedDescriptionTool()
            .with(\.inputs, ["Sources/main.swift"])
            .with(\.trace, true)
            .resolve()
        let trace = try #require(description.arguments[id: .init(rawValue: "trace", commandName: "resolved-description")])
        let descriptionMirrorLabels = Array(Mirror(reflecting: description).children).map(\.label)
        let traceMirrorLabels = Array(Mirror(reflecting: trace).children).map(\.label)

        #expect(description.description == "resolved-description")
        #expect(description.debugDescription.contains("toolName: \"resolved-description\""))
        #expect(descriptionMirrorLabels == ["toolName", "arguments", "subcommands"])
        #expect(trace.description == "--trace")
        #expect(trace.debugDescription.contains("resolved-description.trace"))
        #expect(traceMirrorLabels == ["base", "id", "defaultPosition", "invocationComponents", "invocationArgumentValues", "invocationArguments", "invocationArgument"])
    }

    @Test
    func invocationSummaryCanRenderParentCommandArgumentsFromSubcommands() throws {
        let withoutParentValue = try ParentReferencedSummaryTool()
            .compile()
            .with(\.input, "main.swift")
            .invocation

        let withParentValue = try ParentReferencedSummaryTool()
            .with(\.sdk, "macosx")
            .compile()
            .with(\.input, "main.swift")
            .invocation

        #expect(withoutParentValue == "parent-summary compile main.swift")
        #expect(withParentValue == "parent-summary compile --sdk macosx --sdk-forwarded main.swift")
    }

    @Test
    func booleanFlagsCanSeparateCurrentValueFromRenderDefault() throws {
        #expect(try ConstructorBackedFlagTool().invocation == "constructor-flag")
        #expect(
            try ConstructorBackedFlagTool(disableColoredOutput: true).invocation == "constructor-flag --disable-colored-output"
        )
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
