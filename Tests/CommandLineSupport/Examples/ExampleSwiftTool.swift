#if os(macOS)

import CommandLineToolSupport

final class ExampleSwiftTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "swift"
    }

    override var keyConversion: _CommandLineToolOptionKeyConversion? {
        .doubleHyphenPrefixed
    }

    @Flag(name: "verbose", placement: .local)
    var verbose: Bool = false

    @Option(conversion: .hyphenPrefixed, name: "sdk", placement: .local)
    var sdk: String? = nil

    @Subcommand(of: ExampleSwiftTool.self, name: "build", command: ExampleSwiftBuildTool())
    var build
}

final class ExampleSwiftBuildTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "build"
    }

    override var keyConversion: _CommandLineToolOptionKeyConversion? {
        .doubleHyphenPrefixed
    }

    @Flag
    var configuration: Configuration? = nil

    @Flag(conversion: .hyphenPrefixed, name: "v")
    var verbosity: Int = 0

    @Flag(name: "sandbox", inversion: .prefixedNo)
    var sandbox: Bool? = nil

    @Option(name: "package-path")
    var packagePath: String? = nil

    @Option(name: "triple", separator: .equal)
    var triple: String? = nil

    @Option(conversion: .hyphenPrefixed, name: "Xswiftc", encoding: .singleValue)
    var swiftcOptions: [SwiftcOption] = []

    @Argument(name: nil)
    var explicitProducts: [String] = []
}

extension ExampleSwiftBuildTool {
    enum Configuration: String, CaseIterable, Sendable, CLT.OptionKeyConvertible {
        var name: String {
            rawValue
        }

        case release
    }

    enum SwiftcOption: CLT.ArgumentValueConvertible {
        case define(String)
        case unsafeFlag(String)

        var argumentValue: String {
            switch self {
                case .define(let name):
                    "-D\(name)"
                case .unsafeFlag(let value):
                    value
            }
        }
    }
}

#endif
