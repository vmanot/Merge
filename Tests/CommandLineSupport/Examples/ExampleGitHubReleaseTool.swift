#if os(macOS)

import CommandLineToolSupport

final class ExampleGitHubTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "gh"
    }

    @Option(name: "repo")
    var repository: String? = nil

    @Subcommand(of: ExampleGitHubTool.self, name: "release", command: Release())
    var release

    final class Release: AnyCommandLineTool, CommandLineTool {
        @Subcommand(of: Release.self, name: "create", command: Create())
        var create

        final class Create: AnyCommandLineTool, CommandLineTool {
            @Argument(name: nil)
            var tagName: String? = nil

            @Option(name: "title")
            var title: String? = nil

            @Option(name: "notes")
            var notes: String? = nil

            @Option(name: "notes-file")
            var notesFile: String? = nil

            @Flag(name: "generate-notes")
            var generateNotes: Bool = false

            @Flag(name: "draft")
            var draft: Bool = false

            @Flag(name: "prerelease")
            var prerelease: Bool = false

            @Argument(name: nil)
            var assets: [String] = []

            var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
                \.$tagName
                \.$title

                When(\.$notesFile, .isPresent) {
                    \.$notesFile
                } else: {
                    When(\.$generateNotes, equals: true) {
                        \.$generateNotes
                    } else: {
                        \.$notes
                    }
                }

                \.$draft
                \.$prerelease
                \.$assets
            }
        }
    }
}

#endif
