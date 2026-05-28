#if os(macOS)

import CommandLineToolSupport

final class ExampleDocumentationCompilerTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "docc"
    }

    @Argument(name: nil)
    var operation: Operation = .convert

    @Argument(name: nil)
    var catalogPath: String? = nil

    @Option(name: "output-path")
    var outputPath: String? = nil

    @Flag(name: "transform-for-static-hosting")
    var transformForStaticHosting: Bool = false

    @Option(name: "hosting-base-path")
    var hostingBasePath: String? = nil

    @Option(name: "port")
    var port: Int? = nil

    @Flag(name: "emit-digest")
    var emitDigest: Bool = false

    var invocationSummary: some InvocationSummary {
        Switch(\.$operation) {
            Case(Operation.convert) {
                \.$operation
                \.$catalogPath
                \.$outputPath

                When(\.$transformForStaticHosting, equals: true) {
                    \.$transformForStaticHosting
                    \.$hostingBasePath
                }
            }

            Case(Operation.preview) {
                \.$operation
                \.$catalogPath
                \.$port
            }

            DefaultCase {
                \.$operation
                \.$catalogPath
            }
        }

        if emitDigest {
            \.$emitDigest
        }
    }
}

extension ExampleDocumentationCompilerTool {
    enum Operation: String, CLT.ArgumentValueConvertible {
        case convert
        case preview
        case diagnose

        var argumentValue: String {
            rawValue
        }
    }
}

#endif
