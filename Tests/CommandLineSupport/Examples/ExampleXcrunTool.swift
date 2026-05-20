#if os(macOS)

import CommandLineToolSupport

// Test fixture intentionally mirrors command-line tool spelling.
final class ExampleXcrunTool: AnyCommandLineToolWithSelectedTool, CommandLineTool {
    override var _commandName: String {
        "xcrun"
    }

    @Option(conversion: .hyphenPrefixed, name: "sdk", placement: .local)
    var sdk: String? = nil

    @SelectedTool(of: ExampleXcrunTool.self, name: "swiftc", tool: ExampleSwiftCompilerTool())
    var swiftc

    @SelectedTool(of: ExampleXcrunTool.self, name: "simctl", tool: ExampleSimulatorControlTool())
    var simctl
}

final class ExampleSwiftCompilerTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "swiftc"
    }

    @Flag(conversion: .hyphenPrefixed, name: "typecheck")
    var typecheck: Bool = false

    @Argument(name: nil)
    var inputFiles: [String] = []
}

final class ExampleSimulatorControlTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "simctl"
    }

    @Flag(name: "verbose")
    var verbose: Bool = false

    @Subcommand(of: ExampleSimulatorControlTool.self, name: "io", command: IO())
    var io

    final class IO: AnyCommandLineTool, CommandLineTool {
        override var _commandName: String {
            "io"
        }
    }
}

#endif
