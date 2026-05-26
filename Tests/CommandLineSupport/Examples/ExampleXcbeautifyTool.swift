#if os(macOS)

import CommandLineToolSupport

final class ExampleXcbeautifyTool: AnyCommandLineTool, CommandLineToolOutputFormatterTool {
    override var commandName: CommandLineTool.Name? {
        "xcbeautify"
    }

    @Flag(name: "disable-colored-output")
    var disableColoredOutput: Bool = false
}

#endif
