#if os(macOS)

import CommandLineToolSupport

final class ExampleXcodebuildLikeTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "xcodebuild"
    }

    override var keyConversion: _CommandLineToolOptionKeyConversion? {
        .hyphenPrefixed
    }

    @Option(name: "scheme")
    var scheme: String? = nil

    @Option(name: "workspace")
    var workspace: String? = nil

    @Option(name: "destination")
    var destination: String? = nil

    @Option(name: "derivedDataPath")
    var derivedDataPath: String? = nil

    @Option(name: "enableCodeCoverage")
    var enableCodeCoverage: CodeCoverageMode? = nil

    @Subcommand(of: ExampleXcodebuildLikeTool.self, name: "build", command: Build())
    var build

    @Subcommand(of: ExampleXcodebuildLikeTool.self, name: "test", command: Test())
    var test

    @Subcommand(of: ExampleXcodebuildLikeTool.self, name: "archive", command: Archive())
    var archive

    @Subcommand(of: ExampleXcodebuildLikeTool.self, name: "analyze", command: Analyze())
    var analyze

    @Subcommand(of: ExampleXcodebuildLikeTool.self, name: "clean", command: Clean())
    var clean

    @_SubcommandTool
    final class Test: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "test"
        }

        override var keyConversion: _CommandLineToolOptionKeyConversion? {
            .hyphenPrefixed
        }

        @Option(name: "only-testing")
        var onlyTesting: [String] = []

        @Option(name: "skip-testing")
        var skipTesting: [String] = []

        @Option(name: "testPlan")
        var testPlan: String? = nil

        @Option(name: "resultBundlePath")
        var resultBundlePath: String? = nil

        @Flag(name: "parallel-testing-enabled", inversion: .prefixedNo)
        var parallelTestingEnabled: Bool? = nil

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            NormalizeResultBundlePath()

            self.$workspace
            self.$scheme
            self.$destination
            self.$derivedDataPath
            self.$enableCodeCoverage

            When(\.$testPlan, .isPresent) {
                \.$testPlan
            }

            When(\.$resultBundlePath, .isPresent) {
                \.$resultBundlePath
            }

            When(\.$onlyTesting, .isPresent) {
                \.$onlyTesting
            }

            When(\.$skipTesting, .isPresent) {
                \.$skipTesting
            }

            \.$parallelTestingEnabled
        }

        struct NormalizeResultBundlePath: CommandLineToolInvocationSummary.InvocationSummary {
            typealias Command = Test

            func makeInvocationComponents(
                command: Test,
                parent: AnyCommandLineTool?,
                context: CommandLineToolInvocationSummary.InvocationSummaryContext
            ) throws -> [CommandLineToolInvocation.Component] {
                context.registerRewriteRule(.replaceOptionValues(named: "-resultBundlePath") { values in
                    guard
                        let value = values.elements.first,
                        values.elements.count == 1,
                        !value.rawValue.hasSuffix(".xcresult")
                    else {
                        return values
                    }

                    return [CommandLineToolInvocation.Argument(value.rawValue + ".xcresult")]
                })

                return []
            }
        }
    }

    @_SubcommandTool
    final class Build: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "build"
        }

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            self.$enableCodeCoverage
                ._omitted(
                    unless: .never,
                    reason: "-enableCodeCoverage is intentionally suppressed for build"
                )

            self.$workspace
            self.$scheme
            self.$destination
            self.$derivedDataPath
        }
    }

    @_SubcommandTool
    final class Archive: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "archive"
        }

        override var keyConversion: _CommandLineToolOptionKeyConversion? {
            .hyphenPrefixed
        }

        @Option(name: "archivePath")
        var archivePath: String? = nil

        @Flag(name: "allowProvisioningUpdates")
        var allowProvisioningUpdates: Bool = false

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            self.$workspace
            self.$scheme
            self.$destination
            self.$derivedDataPath
            \.$archivePath

            When(\.$allowProvisioningUpdates, equals: true) {
                \.$allowProvisioningUpdates
            }
        }
    }

    @_SubcommandTool
    final class Analyze: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "analyze"
        }

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            self.$enableCodeCoverage
                ._unavailable(
                    unless: .never,
                    reason: "-enableCodeCoverage is only meaningful for test actions"
                )

            self.$workspace
            self.$scheme
            self.$destination
            self.$derivedDataPath
        }
    }
}

extension ExampleXcodebuildLikeTool {
    @_SubcommandTool
    final class Clean: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "clean"
        }

        var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
            self.$workspace
            self.$derivedDataPath
        }
    }

    enum CodeCoverageMode: String, CLT.ArgumentValueConvertible {
        case enabled = "YES"
        case disabled = "NO"

        var argumentValue: String {
            rawValue
        }
    }
}

#endif
