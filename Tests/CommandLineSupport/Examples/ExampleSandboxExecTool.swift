#if os(macOS)

import CommandLineToolSupport

final class ExampleSandboxExecTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "sandbox-exec"
    }

    @Option(conversion: .hyphenPrefixed, name: "f")
    var profileFilePath: String? = nil

    @Option(conversion: .hyphenPrefixed, name: "p")
    var profile: String? = nil

    @Argument(name: nil)
    var commandAndArguments: [String] = []
}

extension ExampleSandboxExecTool {
    func executing<Tool>(
        _ tool: Tool
    ) throws -> Self where Tool: AnyCommandLineTool & CommandLineTool {
        commandAndArguments = try tool.commandInvocation.argumentValues.map(\.rawValue)

        return self
    }
}

#endif
