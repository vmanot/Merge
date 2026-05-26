//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import CommandLineToolSupport

enum ExampleCoverageMode: String, CLT.ArgumentValueConvertible {
    case enabled = "YES"
    case disabled = "NO"

    var argumentValue: String {
        rawValue
    }
}

final class ExampleNodeApplicabilityTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "applicability-example"
    }

    override var keyConversion: _CommandLineToolOptionKeyConversion? {
        .hyphenPrefixed
    }

    @Option(name: "workspace")
    var workspace: String? = nil

    @Option(name: "enableCoverage")
    var enableCoverage: ExampleCoverageMode? = nil

    @Subcommand(of: ExampleNodeApplicabilityTool.self, name: "build", command: Build())
    var build

    @Subcommand(of: ExampleNodeApplicabilityTool.self, name: "analyze", command: Analyze())
    var analyze

    @Subcommand(of: ExampleNodeApplicabilityTool.self, name: "test", command: Test())
    var test

    @_SubcommandTool
    final class Build: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "build"
        }

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            Omit(self.$enableCoverage)
            self.$workspace
        }
    }

    @_SubcommandTool
    final class Analyze: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "analyze"
        }

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            _Unavailable(self.$enableCoverage, reason: "-enableCoverage is only valid for test")
            self.$workspace
        }
    }

    @_SubcommandTool
    final class Test: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "test"
        }

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            self.$workspace
            self.$enableCoverage
        }
    }
}

final class ExampleModifierApplicabilityTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "applicability-example"
    }

    override var keyConversion: _CommandLineToolOptionKeyConversion? {
        .hyphenPrefixed
    }

    @Option(name: "workspace")
    var workspace: String? = nil

    @Option(name: "enableCoverage")
    var enableCoverage: ExampleCoverageMode? = nil

    @Subcommand(of: ExampleModifierApplicabilityTool.self, name: "build", command: Build())
    var build

    @Subcommand(of: ExampleModifierApplicabilityTool.self, name: "analyze", command: Analyze())
    var analyze

    @Subcommand(of: ExampleModifierApplicabilityTool.self, name: "test", command: Test())
    var test

    @_SubcommandTool
    final class Build: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "build"
        }

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            self.$enableCoverage
                ._omitted(unless: .never, reason: "-enableCoverage is intentionally suppressed for build")

            self.$workspace
        }
    }

    @_SubcommandTool
    final class Analyze: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "analyze"
        }

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            self.$enableCoverage
                ._unavailable(unless: .never, reason: "-enableCoverage is only valid for test")

            self.$workspace
        }
    }

    @_SubcommandTool
    final class Test: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "test"
        }

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            self.$workspace
            self.$enableCoverage
        }
    }
}

#endif
