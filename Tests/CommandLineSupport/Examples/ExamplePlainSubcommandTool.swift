#if os(macOS)

import CommandLineToolSupport

final class ExamplePlainSubcommandTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "plain"
    }

    @Subcommand(of: ExamplePlainSubcommandTool.self, name: "leaf", command: Leaf())
    var leaf

    @Subcommand(of: ExamplePlainSubcommandTool.self, name: "extension-leaf", command: ExtensionLeaf())
    var extensionLeaf

    @_SubcommandTool
    final class Leaf: AnyCommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "leaf"
        }

        @Flag(name: "verbose")
        var verbose: Bool = false
    }
}

extension ExamplePlainSubcommandTool {
    @_SubcommandTool
    final class ExtensionLeaf: AnyCommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "extension-leaf"
        }

        @Flag(name: "dry-run")
        var dryRun: Bool = false
    }
}

#endif
