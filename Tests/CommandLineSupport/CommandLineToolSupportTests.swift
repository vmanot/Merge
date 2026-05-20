#if os(macOS)

import CommandLineToolSupport
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

    @Argument(name: nil, placement: .finalCommand)
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

    @Argument(name: nil)
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

final class FormatterCompatibilityTool: AnyCommandLineTool, CommandLineToolOutputFormatterTool {
    override var _commandName: String {
        "formatter"
    }
}

final class OptionalParameterTool: AnyCommandLineTool, CommandLineTool {
    @Argument
    var value: Any?

    override init() {

    }
}

final class DefaultValueParameterTool: AnyCommandLineTool, CommandLineTool {
    enum Mode: Hashable {
        case disabled
    }

    @Argument
    var mode: Mode = .disabled

    @Argument
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

    @Option(name: "target")
    var target: String? = nil

    @Option(name: "module-name")
    var moduleName: String? = nil

    @Argument(name: nil)
    var inputFiles: [String] = []

    @Option(name: "emit-loaded-module-trace-path")
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
    @Option(name: "output")
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

    @Option(name: "sdk")
    var sdk: String? = nil

    @Subcommand(of: ParentReferencedSummaryTool.self, name: "compile", command: Compile())
    var compile

    final class Compile: AnyCommandLineTool, CommandLineTool, _Subcommand {
        typealias ParentCommand = ParentReferencedSummaryTool

        @Argument(name: nil)
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
    @Option(name: "format")
    var format: String? = nil

    var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        When(\.$format, equals: "json") {
            "--json"
        } else: {
            "--text"
        }
    }
}

final class DuplicateSummaryReferenceTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "duplicate-summary-reference"
    }

    @Option(name: "target")
    var target: String? = nil

    @Argument(name: nil)
    var input: String? = nil

    var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        \.$target
        \.$target
    }
}

final class CollectionPresenceSummaryTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "collection-presence"
    }

    @Argument(name: nil)
    var inputs: [String] = []

    var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        When(\.$inputs, .isPresent) {
            "inputs"
        } else: {
            "no-inputs"
        }
    }
}

final class ResultBuilderBranchSummaryTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "result-builder-branch"
    }

    @Flag(name: "emit-extra")
    var emitExtra: Bool = false

    @Option(name: "name")
    var name: String? = nil

    var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        if emitExtra {
            "extra"
        }

        \.$name
    }
}

final class SwitchWithoutDefaultSummaryTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "switch-without-default"
    }

    @Option(name: "format")
    var format: String? = nil

    var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        Switch(\.$format) {
            Case(value: "json") {
                "--json"
            }
        }
    }
}

final class MultiValueOptionCompatibilityTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "multi-value-options"
    }

    @Option(name: "single", encoding: .singleValue)
    var singleValues: [String] = []

    @Option(name: "space", encoding: .spaceSeparated)
    var spaceValues: [String] = []

    @Option(name: "joined", separator: .equal, encoding: .singleValue)
    var joinedValues: [String] = []
}

final class OptionalBooleanInversionCompatibilityTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "optional-boolean-inversion"
    }

    @Flag(name: "sandbox", inversion: .prefixedNo)
    var sandbox: Bool? = nil

    @Flag(name: "feature", inversion: .prefixedEnableDisable)
    var feature: Bool? = nil
}

final class CustomFlagArrayCompatibilityTool: AnyCommandLineTool, CommandLineTool {
    enum Mode: String, CLT.OptionKeyConvertible {
        case sanitize
        case warnings

        var name: String {
            rawValue
        }
    }

    override var _commandName: String {
        "custom-flag-array"
    }

    @Flag
    var modes: [Mode] = []

    @Flag
    var optionalModes: [Mode]? = nil
}

final class ParentChildConversionSummaryTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "parent-child-conversion"
    }

    override var keyConversion: _CommandLineToolOptionKeyConversion? {
        .hyphenPrefixed
    }

    @Option(name: "sdk")
    var sdk: String? = nil

    @Subcommand(of: ParentChildConversionSummaryTool.self, name: "compile", command: Compile())
    var compile

    final class Compile: AnyCommandLineTool, CommandLineTool, _Subcommand {
        typealias ParentCommand = ParentChildConversionSummaryTool

        override var _commandName: String {
            "compile"
        }

        override var keyConversion: _CommandLineToolOptionKeyConversion? {
            .doubleHyphenPrefixed
        }

        @Option(name: "target")
        var target: String? = nil

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            self.$sdk
            \.$target
        }
    }
}

final class ResolvedDescriptionTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "resolved-description"
    }

    @Option(name: "target")
    var target: String? = nil

    @Argument(name: nil)
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

    @Option(name: "C")
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

@CommandLineTool
final class MacroBackedCompatibilityTool: AnyCommandLineTool {
    override var _commandName: String {
        "macro-backed"
    }
}

@Suite
struct CommandLineToolSupportTests {
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
    func standardStreamWiringRejectsRepeatedExclusiveFormatterEffects() throws {
        typealias Wiring = _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring

        let xcodebuild = Wiring.Stage(role: .primaryInvocation, commandName: "xcodebuild")
        let firstFormatter = Wiring.Stage(
            role: .outputFormatterTool,
            commandName: "xcbeautify",
            streamEffects: [.humanReadableFormatting]
        )
        let secondFormatter = Wiring.Stage(
            role: .outputFormatterTool,
            commandName: "xcbeautify",
            streamEffects: [.humanReadableFormatting]
        )
        let wiring = Wiring(
            stages: [
                xcodebuild,
                firstFormatter,
                secondFormatter
            ],
            streamConnections: [
                Wiring.StreamConnection(
                    output: .init(stageID: xcodebuild.id, stream: .standardOutput),
                    input: .init(stageID: firstFormatter.id, stream: .standardInput)
                ),
                Wiring.StreamConnection(
                    output: .init(stageID: firstFormatter.id, stream: .standardOutput),
                    input: .init(stageID: secondFormatter.id, stream: .standardInput)
                )
            ]
        )

        #expect(throws: Wiring.ValidationError.self) {
            try wiring.validate()
        }
    }

    @Test
    func standardStreamWiringAllowsRepeatedRepeatableFormatterEffects() throws {
        typealias Wiring = _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring

        let repeatableEffect = _CommandLineToolOutputFormatterTool_Semantics.StreamEffect(
            key: "repeatable-normalization",
            composition: .repeatable
        )
        let producer = Wiring.Stage(role: .primaryInvocation, commandName: "producer")
        let firstFormatter = Wiring.Stage(
            role: .outputFormatterTool,
            commandName: "normalizer",
            streamEffects: [repeatableEffect]
        )
        let secondFormatter = Wiring.Stage(
            role: .outputFormatterTool,
            commandName: "normalizer",
            streamEffects: [repeatableEffect]
        )
        let wiring = Wiring(
            stages: [
                producer,
                firstFormatter,
                secondFormatter
            ],
            streamConnections: [
                Wiring.StreamConnection(
                    output: .init(stageID: producer.id, stream: .standardOutput),
                    input: .init(stageID: firstFormatter.id, stream: .standardInput)
                ),
                Wiring.StreamConnection(
                    output: .init(stageID: firstFormatter.id, stream: .standardOutput),
                    input: .init(stageID: secondFormatter.id, stream: .standardInput)
                )
            ]
        )

        try wiring.validate()
    }

    @Test
    func standardStreamWiringModelsObservedFormatterChain() throws {
        typealias Wiring = _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring

        let xcodebuild = Wiring.Stage(role: .primaryInvocation, commandName: "xcrun xcodebuild")
        let buildProgressObservation = Wiring.Stage(role: .external, commandName: "build-progress-observation")
        let xcbeautify = Wiring.Stage(
            role: .outputFormatterTool,
            commandName: "xcbeautify",
            streamEffects: [.humanReadableFormatting]
        )
        let wiring = Wiring(
            stages: [
                xcodebuild,
                buildProgressObservation,
                xcbeautify
            ],
            streamConnections: [
                Wiring.StreamConnection(
                    output: .init(stageID: xcodebuild.id, stream: .standardOutput),
                    input: .init(stageID: buildProgressObservation.id, stream: .standardInput)
                ),
                Wiring.StreamConnection(
                    output: .init(stageID: buildProgressObservation.id, stream: .standardOutput),
                    input: .init(stageID: xcbeautify.id, stream: .standardInput)
                )
            ]
        )

        try wiring.validate()
    }

    @Test
    func standardStreamWiringAllowsSameExclusiveEffectOnIndependentStreamWalks() throws {
        typealias Wiring = _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring

        let firstProducer = Wiring.Stage(role: .primaryInvocation, commandName: "first-producer")
        let secondProducer = Wiring.Stage(role: .external, commandName: "second-producer")
        let firstFormatter = Wiring.Stage(
            role: .outputFormatterTool,
            commandName: "first-formatter",
            streamEffects: [.humanReadableFormatting]
        )
        let secondFormatter = Wiring.Stage(
            role: .outputFormatterTool,
            commandName: "second-formatter",
            streamEffects: [.humanReadableFormatting]
        )
        let wiring = Wiring(
            stages: [
                firstProducer,
                secondProducer,
                firstFormatter,
                secondFormatter
            ],
            streamConnections: [
                Wiring.StreamConnection(
                    output: .init(stageID: firstProducer.id, stream: .standardOutput),
                    input: .init(stageID: firstFormatter.id, stream: .standardInput)
                ),
                Wiring.StreamConnection(
                    output: .init(stageID: secondProducer.id, stream: .standardOutput),
                    input: .init(stageID: secondFormatter.id, stream: .standardInput)
                )
            ]
        )

        try wiring.validate()
    }

    @Test
    func standardStreamWiringRejectsMissingStageReferences() throws {
        typealias Wiring = _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring

        let producer = Wiring.Stage(role: .primaryInvocation, commandName: "producer")
        let missingStageID = UUID()
        let wiring = Wiring(
            stages: [producer],
            streamConnections: [
                Wiring.StreamConnection(
                    output: .init(stageID: producer.id, stream: .standardOutput),
                    input: .init(stageID: missingStageID, stream: .standardInput)
                )
            ]
        )

        try expectStandardStreamWiringValidationError(wiring, equals: .missingStage(missingStageID))
    }

    @Test
    func standardStreamWiringRejectsBackwardEndpointDirections() throws {
        typealias Wiring = _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring

        let producer = Wiring.Stage(role: .primaryInvocation, commandName: "producer")
        let consumer = Wiring.Stage(role: .external, commandName: "consumer")
        let invalidOutput = Wiring.StreamEndpoint(stageID: producer.id, stream: .standardInput)
        let invalidInput = Wiring.StreamEndpoint(stageID: consumer.id, stream: .standardOutput)

        try expectStandardStreamWiringValidationError(
            Wiring(
                stages: [producer, consumer],
                streamConnections: [
                    Wiring.StreamConnection(
                        output: invalidOutput,
                        input: .init(stageID: consumer.id, stream: .standardInput)
                    )
                ]
            ),
            equals: .invalidOutputEndpoint(invalidOutput)
        )

        try expectStandardStreamWiringValidationError(
            Wiring(
                stages: [producer, consumer],
                streamConnections: [
                    Wiring.StreamConnection(
                        output: .init(stageID: producer.id, stream: .standardOutput),
                        input: invalidInput
                    )
                ]
            ),
            equals: .invalidInputEndpoint(invalidInput)
        )
    }

    @Test
    func standardStreamWiringRejectsAccidentalFanoutAndFanin() throws {
        typealias Wiring = _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring

        let producer = Wiring.Stage(role: .primaryInvocation, commandName: "producer")
        let firstConsumer = Wiring.Stage(role: .external, commandName: "first-consumer")
        let secondConsumer = Wiring.Stage(role: .external, commandName: "second-consumer")
        let output = Wiring.StreamEndpoint(stageID: producer.id, stream: .standardOutput)
        let input = Wiring.StreamEndpoint(stageID: firstConsumer.id, stream: .standardInput)

        try expectStandardStreamWiringValidationError(
            Wiring(
                stages: [producer, firstConsumer, secondConsumer],
                streamConnections: [
                    Wiring.StreamConnection(
                        output: output,
                        input: input
                    ),
                    Wiring.StreamConnection(
                        output: output,
                        input: .init(stageID: secondConsumer.id, stream: .standardInput)
                    )
                ]
            ),
            equals: .multipleConnectionsFromOutput(output)
        )

        try expectStandardStreamWiringValidationError(
            Wiring(
                stages: [producer, firstConsumer, secondConsumer],
                streamConnections: [
                    Wiring.StreamConnection(
                        output: output,
                        input: input
                    ),
                    Wiring.StreamConnection(
                        output: .init(stageID: secondConsumer.id, stream: .standardOutput),
                        input: input
                    )
                ]
            ),
            equals: .multipleConnectionsToInput(input)
        )
    }

    @Test
    func standardStreamWiringRejectsStageCycles() throws {
        typealias Wiring = _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring

        let firstStage = Wiring.Stage(role: .primaryInvocation, commandName: "first")
        let secondStage = Wiring.Stage(role: .external, commandName: "second")
        let wiring = Wiring(
            stages: [firstStage, secondStage],
            streamConnections: [
                Wiring.StreamConnection(
                    output: .init(stageID: firstStage.id, stream: .standardOutput),
                    input: .init(stageID: secondStage.id, stream: .standardInput)
                ),
                Wiring.StreamConnection(
                    output: .init(stageID: secondStage.id, stream: .standardOutput),
                    input: .init(stageID: firstStage.id, stream: .standardInput)
                )
            ]
        )

        do {
            try wiring.validate()
            Issue.record("Expected standard stream wiring cycle validation to throw.")
        } catch let error as Wiring.ValidationError {
            guard case .cycleDetected(let stageIDs) = error else {
                Issue.record("Expected cycleDetected, got \(error).")
                return
            }

            #expect(stageIDs.first == firstStage.id)
            #expect(stageIDs.last == firstStage.id)
        } catch {
            Issue.record("Expected \(Wiring.ValidationError.self), got \(error).")
        }
    }

    private func expectStandardStreamWiringValidationError(
        _ wiring: _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring,
        equals expectedError: _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring.ValidationError,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        do {
            try wiring.validate()
            Issue.record("Expected standard stream wiring validation to throw.", sourceLocation: sourceLocation)
        } catch let error as _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring.ValidationError {
            #expect(error == expectedError, sourceLocation: sourceLocation)
        } catch {
            Issue.record("Expected standard stream wiring validation error, got \(error).", sourceLocation: sourceLocation)
        }
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
    func commandLineToolModelMacroSynthesizesCommandLineToolConformance() {
        let executionRecordType: _CommandLineToolExecutionRecord<MacroBackedCompatibilityTool>.Type = _CommandLineToolExecutionRecord<MacroBackedCompatibilityTool>.self
        let tool: any CommandLineTool = MacroBackedCompatibilityTool()

        #expect(executionRecordType == _CommandLineToolExecutionRecord<MacroBackedCompatibilityTool>.self)
        #expect(tool._commandName == "macro-backed")
    }

    @Test
    func structuredInvocationPreservesStringInvocation() throws {
        let command = CompatibilityRootTool()
            .with(\.force, true)
            .with(\.path, "Sources")

        let invocation = try command.commandInvocation

        #expect(invocation.argumentValues == [
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
        #expect(mirrorLabels == ["components", "argumentValues", "rawComponents", "commandName", "arguments", "commandLine"])
        #expect(argument.description == "--force")
        #expect(argument.posixShellEscapedValue == "'--force'")
        #expect(argument.debugDescription == "CommandLineToolInvocation.Argument(.string(\"--force\"))")
        #expect(argumentMirrorLabels == ["storage", "stringValue", "rawValue", "rawBytes"])
    }

    @Test
    func structuredInvocationExposesGrammarAwareComponents() throws {
        let invocation = try CompatibilityRootTool()
            .with(\.force, true)
            .with(\.path, "Sources")
            .commandInvocation
        let components = invocation.components

        #expect(components.map(\.kind) == [.executable, .positionalArgument, .positionalArgument])
        #expect(components.map(\.rawValues) == [["root"], ["--force"], ["Sources"]])
        #expect(components.first?.description == "root")
        #expect(components.first?.debugDescription.contains("executable") == true)
        #expect(Array(Mirror(reflecting: try #require(components.first)).children).map(\.label) == ["kind", "arguments", "key", "separator", "values", "multiValueEncoding", "rawValues"])
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

    @Test("CommandLineTool _run uses direct argv execution for modeled invocations")
    func commandLineToolRunUsesDirectArgvExecutionForModeledInvocations() async throws {
        let tool = EchoCompatibilityTool()
        let invocation = CommandLineToolInvocation(
            components: [
                "printf",
                "%s",
                "direct; echo shell-was-used"
            ]
        )
        let record = try await tool._run(
            invocation: invocation,
            applying: .standardStreamMirroring(.disabled)
        )

        #expect(invocation.executableInvocation?.arguments.rawValues == ["%s", "direct; echo shell-was-used"])
        #expect(record.stdoutString == "direct; echo shell-was-used")
    }

    @Test("CommandLineTool execution plans are pre-execution complements to records")
    func commandLineToolExecutionPlanRunsModeledInvocation() async throws {
        let tool = EchoCompatibilityTool()
            .with(\.text, "planned-record")
        let plan = try tool._executionPlan(applying: .standardStreamMirroring(.disabled))
        let record = try await plan._run()

        #expect(plan.tool === tool)
        #expect(plan.commandLine == "echo planned-record")
        #expect(plan.invocation?.commandLine == "echo planned-record")
        #expect(plan.selectedToolInvocation == nil)
        #expect(record.commandLine == plan.commandLine)
        #expect(record.stdoutString == "planned-record")
    }

    @Test("Command-line tools record successful execution attempts")
    func commandLineToolsRecordSuccessfulExecutionAttempts() async throws {
        let tool = EchoCompatibilityTool()
            .with(\.text, "attempt-record")
        let record = try await tool._run(applying: .standardStreamMirroring(.disabled))
        let attempts = await tool._internalState._executionAttempts
        let attempt = try #require(attempts.first)

        #expect(attempts.count == 1)
        #expect(attempt.shellScopeID != nil)
        #expect(attempt.source.commandLine == record.commandLine)
        #expect(attempt.finishedAt >= attempt.startedAt)

        switch attempt.result {
            case .success(let recorded):
                #expect(recorded.commandLine == "echo attempt-record")
                #expect(recorded.stdoutString == "attempt-record")
            case .failure(let error):
                Issue.record("Expected a successful execution attempt, got \(String(reflecting: error)).")
        }
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
    func invocationSummaryExplicitReferencesSuppressFallbackDuplication() throws {
        let command = try DuplicateSummaryReferenceTool()
            .with(\.target, "arm64-apple-macos")
            .with(\.input, "main.swift")
            .invocation

        #expect(command == "duplicate-summary-reference --target arm64-apple-macos main.swift")
    }

    @Test
    func invocationSummaryPresenceTreatsEmptyCollectionsAsAbsent() throws {
        let emptyCommand = try CollectionPresenceSummaryTool()
            .invocation
        let nonEmptyCommand = try CollectionPresenceSummaryTool()
            .with(\.inputs, ["main.swift", "support.swift"])
            .invocation

        #expect(emptyCommand == "collection-presence no-inputs")
        #expect(nonEmptyCommand == "collection-presence inputs main.swift support.swift")
    }

    @Test
    func invocationSummarySupportsResultBuilderBranches() throws {
        let plainCommand = try ResultBuilderBranchSummaryTool()
            .with(\.name, "baseline")
            .invocation
        let extraCommand = try ResultBuilderBranchSummaryTool()
            .with(\.emitExtra, true)
            .with(\.name, "diagnostic")
            .invocation

        #expect(plainCommand == "result-builder-branch --name baseline")
        #expect(extraCommand == "result-builder-branch extra --name diagnostic --emit-extra")
    }

    @Test
    func invocationSummarySwitchWithoutDefaultThrowsWhenNoCaseMatches() throws {
        let command = SwitchWithoutDefaultSummaryTool()
            .with(\.format, "yaml")

        #expect(throws: (any Error).self) {
            _ = try command.invocation
        }
    }

    @Test
    func multiValueOptionsPreserveEncodingStructure() throws {
        let description = try MultiValueOptionCompatibilityTool()
            .with(\.singleValues, ["a", "b"])
            .with(\.spaceValues, ["ios", "macos"])
            .with(\.joinedValues, ["one", "two"])
            .resolve()

        let single = try #require(description.arguments[id: .init(rawValue: "singleValues", commandName: "multi-value-options")])
        let space = try #require(description.arguments[id: .init(rawValue: "spaceValues", commandName: "multi-value-options")])
        let joined = try #require(description.arguments[id: .init(rawValue: "joinedValues", commandName: "multi-value-options")])

        #expect(single.invocationArguments == ["--single", "a", "--single", "b"])
        #expect(single.publicInvocationComponents == [
            .option(
                key: CommandLineToolInvocation.Argument("--single"),
                separator: .space,
                values: CommandLineToolInvocation.Arguments(["a", "b"]),
                multiValueEncoding: .singleValue
            )
        ])
        #expect(space.invocationArguments == ["--space", "ios", "macos"])
        #expect(space.publicInvocationComponents.first?.multiValueEncoding == .spaceSeparated)
        #expect(joined.invocationArguments == ["--joined=one", "--joined=two"])
        #expect(joined.publicInvocationComponents.first?.separator == .equal)
    }

    @Test
    func optionalBooleanInversionFlagsPreserveNilTrueAndFalseStates() throws {
        #expect(try OptionalBooleanInversionCompatibilityTool().invocation == "optional-boolean-inversion")
        #expect(
            try OptionalBooleanInversionCompatibilityTool()
                .with(\.sandbox, true)
                .with(\.feature, true)
                .invocation == "optional-boolean-inversion --sandbox --enable-feature"
        )
        #expect(
            try OptionalBooleanInversionCompatibilityTool()
                .with(\.sandbox, false)
                .with(\.feature, false)
                .invocation == "optional-boolean-inversion --no-sandbox --disable-feature"
        )
    }

    @Test
    func customFlagArraysResolveConcreteAndOptionalCollections() throws {
        let description = try CustomFlagArrayCompatibilityTool()
            .with(\.modes, [.sanitize, .warnings])
            .with(\.optionalModes, [.warnings])
            .resolve()

        let modes = try #require(description.arguments[id: .init(rawValue: "modes", commandName: "custom-flag-array")])
        let optionalModes = try #require(description.arguments[id: .init(rawValue: "optionalModes", commandName: "custom-flag-array")])

        #expect(modes.invocationArguments == ["--sanitize", "--warnings"])
        #expect(optionalModes.invocationArguments == ["--warnings"])
        #expect(modes.publicInvocationComponents.map(\.kind) == [.flag, .flag])
    }

    @Test
    func parentSummaryReferencesUseParentKeyConversionNotChildKeyConversion() throws {
        let command = try ParentChildConversionSummaryTool()
            .with(\.sdk, "macosx")
            .compile()
            .with(\.target, "arm64-apple-macos")
            .invocation

        #expect(command == "parent-child-conversion compile -sdk macosx --target arm64-apple-macos")
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
        #expect(target.publicInvocationComponents == [
            .option(
                key: CommandLineToolInvocation.Argument("--target"),
                separator: .space,
                values: [CommandLineToolInvocation.Argument("arm64-apple-macosx15.0")]
            )
        ])
        #expect(target.publicInvocationComponents.first?.key == CommandLineToolInvocation.Argument("--target"))
        #expect(target.publicInvocationComponents.first?.values == CommandLineToolInvocation.Arguments(["arm64-apple-macosx15.0"]))
        #expect(target.publicInvocationComponents.first?.rawValues == ["--target", "arm64-apple-macosx15.0"])
        #expect(inputs.invocationArguments == ["Sources/main.swift", "Sources/support.swift"])
        #expect(inputs.invocationComponents.map(\.kind) == [.positionalArgument, .positionalArgument])
        #expect(inputs.publicInvocationComponents.map(\.kind) == [.positionalArgument, .positionalArgument])
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
        #expect(traceMirrorLabels == ["base", "id", "defaultPosition", "invocationComponents", "publicInvocationComponents", "invocationArgumentValues", "invocationArguments", "invocationArgument"])
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

    @Test("Legacy output formatter attachment rejects double attachment")
    func legacyOutputFormatterAttachmentRejectsDoubleAttachment() throws {
        let tool = CompatibilityLeafTool()

        try tool._attachOutputFormatterTool(FormatterCompatibilityTool())

        do {
            try tool._attachOutputFormatterTool(FormatterCompatibilityTool())

            Issue.record("Expected double output formatter attachment to fail.")
        } catch AnyCommandLineTool._DeveloperError.outputFormatterToolAlreadyAttached {
        } catch {
            Issue.record("Expected outputFormatterToolAlreadyAttached, got \(error).")
        }
    }

    @Test("Legacy output formatter attachment can be reset explicitly")
    func legacyOutputFormatterAttachmentCanBeResetExplicitly() throws {
        let tool = CompatibilityLeafTool()

        try tool._attachOutputFormatterTool(FormatterCompatibilityTool())
        tool._detachOutputFormatterTool()
        try tool._attachOutputFormatterTool(FormatterCompatibilityTool())

        #expect(tool._attachedOutputFormatterTool is FormatterCompatibilityTool)
    }

}

#endif
