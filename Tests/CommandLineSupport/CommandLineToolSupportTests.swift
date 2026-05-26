#if os(macOS)

import CommandLineToolSupport
import Foundation
import Merge
import ShellScripting
import Testing

final class CompatibilityRootTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
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
    override var commandName: CommandLineTool.Name? {
        "leaf"
    }
}

final class EchoCompatibilityTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "echo"
    }

    @Argument(name: nil)
    var text: String? = nil

    @Subcommand(of: EchoCompatibilityTool.self, name: "nested", command: EchoNestedCompatibilityTool())
    var nested
}

final class EchoNestedCompatibilityTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "nested"
    }
}

final class TrueCompatibilityTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "true"
    }
}

final class FormatterCompatibilityTool: AnyCommandLineTool, CommandLineToolOutputFormatterTool {
    override var commandName: CommandLineTool.Name? {
        "formatter"
    }
}

final class SummaryModeTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
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
    override var commandName: CommandLineTool.Name? {
        "conditional-summary"
    }

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

final class OmittedSummaryTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "omitted-summary"
    }

    @Flag(name: "verbose")
    var verbose: Bool = false

    @Option(name: "output")
    var output: String? = nil

    var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        Omit(\OmittedSummaryTool.$verbose)
        \.$output
    }
}

final class ConflictingDispositionSummaryTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "conflicting-disposition"
    }

    @Option(name: "output")
    var output: String? = nil

    var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        Omit(\ConflictingDispositionSummaryTool.$output)
        \.$output
    }
}

final class UnavailableSummaryTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "unavailable-summary"
    }

    @Flag(name: "verbose")
    var verbose: Bool = false

    @Option(name: "output")
    var output: String? = nil

    @Argument(name: nil)
    var input: String? = nil

    var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        _Unavailable(\UnavailableSummaryTool.$output, reason: "--output is not accepted by this mode")
        \.$verbose
        \.$input
    }
}

final class RewrittenSummaryTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "rewritten-summary"
    }

    @Option(name: "output")
    var output: String? = nil

    @Argument(name: nil)
    var input: String? = nil

    var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        RewriteAfterDefaultSummary()
    }
}

struct RewriteAfterDefaultSummary: CommandLineToolInvocationSummary.InvocationSummary {
    typealias Command = RewrittenSummaryTool

    func makeInvocationComponents(
        command: RewrittenSummaryTool,
        parent: AnyCommandLineTool?,
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        context.registerRewriteRule(.replaceOptionValues(named: "--output") { values in
            values.rawValues == ["raw.txt"] ? ["rewritten.txt"] : values
        })
        context.registerRewriteRule(.init { invocation in
            invocation.components.append(.positionalArgument("rewrite-applied"))
        })

        return []
    }
}

final class ParentReferencedSummaryTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "parent-summary"
    }

    @Option(name: "sdk")
    var sdk: String? = nil

    @Subcommand(of: ParentReferencedSummaryTool.self, name: "compile", command: Compile())
    var compile

    @_SubcommandTool
    final class Compile: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "compile"
        }

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

final class ParentUnavailableSummaryTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "parent-unavailable"
    }

    @Option(name: "sdk")
    var sdk: String? = nil

    @Subcommand(of: ParentUnavailableSummaryTool.self, name: "build", command: Build())
    var build

    @_SubcommandTool
    final class Build: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "build"
        }

        @Argument(name: nil)
        var input: String? = nil

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            _Unavailable(self.$sdk, reason: "--sdk does not apply to build")
            \.$input
        }
    }
}

final class ExactConditionalSummaryTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "exact-conditional-summary"
    }

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
    override var commandName: CommandLineTool.Name? {
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
    override var commandName: CommandLineTool.Name? {
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
    override var commandName: CommandLineTool.Name? {
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
    override var commandName: CommandLineTool.Name? {
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
    override var commandName: CommandLineTool.Name? {
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
    override var commandName: CommandLineTool.Name? {
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

    override var commandName: CommandLineTool.Name? {
        "custom-flag-array"
    }

    @Flag
    var modes: [Mode] = []

    @Flag
    var optionalModes: [Mode]? = nil
}

final class ParentChildConversionSummaryTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "parent-child-conversion"
    }

    override var keyConversion: _CommandLineToolOptionKeyConversion? {
        .hyphenPrefixed
    }

    @Option(name: "sdk")
    var sdk: String? = nil

    @Subcommand(of: ParentChildConversionSummaryTool.self, name: "compile", command: Compile())
    var compile

    @_SubcommandTool
    final class Compile: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
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
    override var commandName: CommandLineTool.Name? {
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
    override var commandName: CommandLineTool.Name? {
        "url-parameter"
    }

    @Option(name: "C")
    var checkoutURL: URL? = nil
}

final class ConstructorBackedFlagTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
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

final class XcrunHostToolFixture: AnyCommandLineToolWithSelectedTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "xcrun"
    }

    @Option(conversion: .hyphenPrefixed, name: "sdk", placement: .local)
    var sdk: String? = nil
}

final class HostedNotarytoolFixture: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "notarytool"
    }

    @Subcommand(of: HostedNotarytoolFixture.self, name: "submit", command: Submit())
    var submit

    init(hostTool: XcrunHostToolFixture = XcrunHostToolFixture()) {
        super.init()

        try! _attachHostTool(.toolThatResolvesAndInvokesSelectedTool(hostTool))
    }

    final class Submit: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "submit"
        }
    }
}

final class PrintfSelectingTool: AnyCommandLineToolWithSelectedTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "printf"
    }

    @SelectedTool(of: PrintfSelectingTool.self, name: "selected-tool", tool: SelectedPrintfPayloadTool())
    var payload
}

final class SelectedPrintfPayloadTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "underlying-selected-tool"
    }
}

final class SelectedPrintfPayloadWithSubcommandTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "underlying-selected-parent"
    }

    @Flag(name: "verbose")
    var verbose: Bool = false

    @Subcommand(of: SelectedPrintfPayloadWithSubcommandTool.self, name: "child", command: Child())
    var child

    final class Child: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "child"
        }
    }
}

@CommandLineTool("macro-backed")
final class MacroBackedCompatibilityTool: AnyCommandLineTool {

}

@CommandLineTool(name: CommandLineTool.Name("macro-name-backed"))
final class MacroNameBackedCompatibilityTool: AnyCommandLineTool {

}

@CommandLineTool(_CommandLineTool_Name("legacy-macro-name-backed"))
final class LegacyMacroNameBackedCompatibilityTool: AnyCommandLineTool {

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
    func resolvedDescriptionChainPreservesSubcommandChain() throws {
        let command = CompatibilityRootTool()
            .with(\.verbose, true)
            .with(\.force, true)
            .with(\.path, "Sources")
            .leaf
        let chain = try command._resolvedDescriptionChain

        #expect(chain.map(\.commandName) == ["root", "leaf"])
        #expect(chain[0].arguments.map(\.id.rawValue) == ["verbose", "force", "path"])
        #expect(chain[1].arguments.isEmpty)
        #expect(try command.invocation == "root leaf --verbose --force Sources")
    }

    @Test
    func resolvedDescriptionChainPreservesSelectedToolChain() throws {
        let command = ExampleXcrunTool()
            .simctl()
            .io()
        let chain = try command._resolvedDescriptionChain

        #expect(chain.map(\.commandName) == ["xcrun", "simctl", "io"])
        #expect(try command.invocation == "xcrun simctl io")
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
    func attachedHostToolRendersToolThatResolvesAndInvokesSelectedTool() throws {
        let command = HostedNotarytoolFixture(
            hostTool: XcrunHostToolFixture().with(\.sdk, "macosx")
        )
        .submit()
        let invocation = try command.commandInvocation
        let plan = command._executionPlan(invocation: invocation)

        #expect(invocation.commandLine == "xcrun -sdk macosx notarytool submit")
        #expect(plan.selectedToolInvocation?.selectingToolCommandName == "xcrun")
        #expect(plan.selectedToolInvocation?.selectedToolCommandName == "notarytool")
        #expect(plan.selectedToolInvocation?.selectedToolCommandPath == ["notarytool", "submit"])
        #expect(plan.selectedToolInvocation?.selectionSemantics == .staticExplicitArgument)
        #expect(plan.selectedToolInvocation?.resolutionSemantics == .resolvesBeforeInvocationAndInvokesThroughSelectingTool)
    }

    @Test
    func attachedHostToolRejectsDoubleAttachment() throws {
        let tool = HostedNotarytoolFixture()

        do {
            try tool._attachHostTool(.toolThatResolvesAndInvokesSelectedTool(XcrunHostToolFixture()))

            Issue.record("Expected double host tool attachment to fail.")
        } catch AnyCommandLineTool._DeveloperError.hostToolAlreadyAttached {
        } catch {
            Issue.record("Expected hostToolAlreadyAttached, got \(error).")
        }
    }

    @Test
    func commandLineToolModelMacroSynthesizesCommandLineToolConformance() {
        let executionRecordType: _CommandLineToolExecutionRecord<MacroBackedCompatibilityTool>.Type = _CommandLineToolExecutionRecord<MacroBackedCompatibilityTool>.self
        let tool: any CommandLineTool = MacroBackedCompatibilityTool()
        let nameBackedTool: any CommandLineTool = MacroNameBackedCompatibilityTool()
        let legacyNameBackedTool: any CommandLineTool = LegacyMacroNameBackedCompatibilityTool()

        #expect(executionRecordType == _CommandLineToolExecutionRecord<MacroBackedCompatibilityTool>.self)
        #expect(tool.requireCommandName().rawValue == "macro-backed")
        #expect(nameBackedTool.requireCommandName().rawValue == "macro-name-backed")
        #expect(legacyNameBackedTool.requireCommandName().rawValue == "legacy-macro-name-backed")
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
        #expect(invocation.renderedShellCommandString(using: .posixShellCommandLine) == _ShellCommandString(rawValue: "'root' '--force' 'Sources'", dialect: .posix))
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
        #expect(invocation.components.last?.values.elements.first?.storage == .path("/tmp/path with spaces"))
        #expect(invocation.executableInvocation?.arguments.rawValues == ["-C", "/tmp/path with spaces"])
    }

    @Test
    func structuredInvocationExposesGrammarAwareComponents() throws {
        let invocation = try CompatibilityRootTool()
            .with(\.force, true)
            .with(\.path, "Sources")
            .commandInvocation
        let components = invocation.components

        #expect(components.map(\.kind) == [.executable, .flag, .positionalArgument])
        #expect(components.map(\.rawValues) == [["root"], ["--force"], ["Sources"]])
        #expect(components.first?.description == "root")
    }

    @Test
    func structuredInvocationArgumentReflectsRawBytes() throws {
        let argument = CommandLineToolInvocation.Argument(rawBytes: [0xff])
        let emptyArgument = CommandLineToolInvocation.Argument("")
        let quotedArgument = CommandLineToolInvocation.Argument("it's here")

        #expect(argument.storage == .rawBytes([0xff]))
        #expect(argument.stringValue == nil)
        #expect(argument.rawBytes == [0xff])
        #expect(emptyArgument.posixShellEscapedValue == "''")
        #expect(quotedArgument.posixShellEscapedValue == "'it'\\''s here'")
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
        #expect(record.source.description == "echo modeled-record")
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
        #expect(invocation.rawComponents == ["root", "--force", "Sources", "status", "--porcelain"])
        #expect(invocation.arguments.map(\.rawValue) == ["--force", "Sources", "status", "--porcelain"])
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
        #expect(coupled.tool.selectedTool.requireCommandName().rawValue == "underlying-selected-tool")
        #expect(decoupled.tool.selectedTool.requireCommandName().rawValue == "underlying-selected-tool")
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

        #expect(writeCommand == "conditional-summary write --output trace.json --verbose")
        #expect(dryRunCommand == "conditional-summary dry-run --verbose")
    }

    @Test
    func invocationSummaryCanOmitCurrentCommandArguments() throws {
        let command = try OmittedSummaryTool()
            .with(\.verbose, true)
            .with(\.output, "out.txt")
            .invocation

        #expect(command == "omitted-summary --output out.txt")
    }

    @Test
    func invocationSummaryConflictingDispositionsThrowStructuredErrors() throws {
        do {
            _ = try ConflictingDispositionSummaryTool()
                .with(\.output, "out.txt")
                .invocation

            Issue.record("Expected conflicting invocation-summary argument dispositions to throw.")
        } catch let error as CommandLineToolInvocationSummary.Error {
            guard case .conflictingArgumentDisposition(let command, let argument, let existing, let new, let location) = error else {
                Issue.record("Expected conflictingArgumentDisposition, got \(error).")
                return
            }

            #expect(command == "conflicting-disposition")
            #expect(argument.rawValue == "output")
            #expect(argument.commandName == "conflicting-disposition")
            #expect(existing.disposition == .omitted)
            #expect(new.disposition == .explicitRender)
            #expect(new.components.map(\.kind) == [.option])
            #expect(location != nil)
        } catch {
            Issue.record("Expected invocation-summary error, got \(error).")
        }
    }

    @Test
    func invocationSummaryUnavailableAllowsAbsentCurrentCommandArguments() throws {
        let command = try UnavailableSummaryTool()
            .with(\.verbose, true)
            .with(\.input, "main.swift")
            .invocation

        #expect(command == "unavailable-summary --verbose main.swift")
    }

    @Test
    func invocationSummaryUnavailableRejectsCurrentCommandArgumentsWhenRendered() throws {
        do {
            _ = try UnavailableSummaryTool()
                .with(\.output, "out.txt")
                .with(\.input, "main.swift")
                .invocation

            Issue.record("Expected unavailable invocation-summary argument to throw.")
        } catch let error as CommandLineToolInvocationSummary.Error {
            guard case .unsupportedArgument(let command, let argument, let disposition, let components, let reason, let location) = error else {
                Issue.record("Expected unsupportedArgument, got \(error).")
                return
            }

            #expect(command == "unavailable-summary")
            #expect(argument.rawValue == "output")
            #expect(argument.commandName == "unavailable-summary")
            #expect(disposition == .unavailable)
            #expect(components.map(\.kind) == [.option])
            #expect(reason == "--output is not accepted by this mode")
            #expect(location != nil)
        } catch {
            Issue.record("Expected invocation-summary error, got \(error).")
        }
    }

    @Test
    func invocationSummaryUnavailableRejectsParentArgumentsWhenRendered() throws {
        do {
            _ = try ParentUnavailableSummaryTool()
                .with(\.sdk, "macosx")
                .build()
                .with(\.input, "main.swift")
                .invocation

            Issue.record("Expected unavailable parent invocation-summary argument to throw.")
        } catch let error as CommandLineToolInvocationSummary.Error {
            guard case .unsupportedArgument(let command, let argument, let disposition, let components, let reason, let location) = error else {
                Issue.record("Expected unsupportedArgument, got \(error).")
                return
            }

            #expect(command == "parent-unavailable")
            #expect(argument.rawValue == "sdk")
            #expect(argument.commandName == "parent-unavailable")
            #expect(disposition == .unavailable)
            #expect(components.map(\.kind) == [.option])
            #expect(reason == "--sdk does not apply to build")
            #expect(location != nil)
        } catch {
            Issue.record("Expected invocation-summary error, got \(error).")
        }
    }

    @Test
    func invocationSummaryUnavailableAllowsAbsentParentArguments() throws {
        let command = try ParentUnavailableSummaryTool()
            .build()
            .with(\.input, "main.swift")
            .invocation

        #expect(command == "parent-unavailable build main.swift")
    }

    @Test
    func invocationSummaryRewriteRulesRunAfterDefaultCompletion() throws {
        let command = try RewrittenSummaryTool()
            .with(\.output, "raw.txt")
            .with(\.input, "main.swift")
            .invocation

        #expect(command == "rewritten-summary --output rewritten.txt main.swift rewrite-applied")
    }

    @Test
    func invocationSummaryCanUseReadableEqualityConditions() throws {
        let jsonCommand = try ExactConditionalSummaryTool()
            .with(\.format, "json")
            .invocation

        let textCommand = try ExactConditionalSummaryTool()
            .with(\.format, "text")
            .invocation

        #expect(jsonCommand == "exact-conditional-summary --json --format json")
        #expect(textCommand == "exact-conditional-summary --text --format text")
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

        do {
            _ = try command.invocation

            Issue.record("Expected invocation-summary switch without matching case to throw.")
        } catch let error as CommandLineToolInvocationSummary.Error {
            guard case .noSwitchCaseMatched(let command, let argument, let valueDescription, let location) = error else {
                Issue.record("Expected noSwitchCaseMatched, got \(error).")
                return
            }

            #expect(command == "switch-without-default")
            #expect(argument?.rawValue == "format")
            #expect(valueDescription == "Optional(\"yaml\")")
            #expect(location != nil)
        } catch {
            Issue.record("Expected invocation-summary error, got \(error).")
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
    func parentInvocationSummaryReferencesThrowStructuredErrorsWithoutParent() throws {
        do {
            _ = try ParentReferencedSummaryTool.Compile()
                .with(\.input, "main.swift")
                .invocation

            Issue.record("Expected missing parent invocation-summary error.")
        } catch let error as CommandLineToolInvocationSummary.Error {
            guard case .missingExpectedParent(let command, let expectedParent, let actualParent, _) = error else {
                Issue.record("Expected missingExpectedParent, got \(error).")
                return
            }

            #expect(ObjectIdentifier(command) == ObjectIdentifier(ParentReferencedSummaryTool.Compile.self))
            #expect(ObjectIdentifier(expectedParent) == ObjectIdentifier(ParentReferencedSummaryTool.self))
            #expect(actualParent == nil)
        } catch {
            Issue.record("Expected invocation-summary error, got \(error).")
        }
    }

    @Test
    func defaultInvocationArgumentsUseStructuralArgumentCarrier() throws {
        let tool = ResolvedDescriptionTool()
            .with(\.target, "arm64-apple-macosx15.0")
            .with(\.inputs, ["Sources/main.swift"])
        let context = CommandLineToolInvocationSummary.InvocationSummaryContext()

        let localArguments = try tool._defaultInvocationArguments(
            context: context,
            positions: [.local]
        )

        #expect(localArguments == CommandLineToolInvocation.Arguments([
            "--target",
            "arm64-apple-macosx15.0",
            "Sources/main.swift"
        ]))
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
