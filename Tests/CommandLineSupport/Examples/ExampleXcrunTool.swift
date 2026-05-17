#if os(macOS)

import CommandLineToolSupport

// Test fixture intentionally mirrors command-line tool spelling.
final class ExampleXcrunTool: AnyCommandLineToolWithSelectedTool, CommandLineTool {
    override var _commandName: String {
        "xcrun"
    }

    @Subcommand(of: ExampleXcrunTool.self, name: "simctl", command: simctl())
    var simctl

    final class simctl: AnyCommandLineTool, CommandLineTool {
        override var _commandName: String {
            "simctl"
        }

        @Subcommand(of: simctl.self, name: "io", command: io())
        var io

        final class io: AnyCommandLineTool, CommandLineTool {
            override var _commandName: String {
                "io"
            }
        }
    }
}

#endif
