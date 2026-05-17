#if os(macOS)

import CommandLineToolSupport
import Foundation

final class ExampleGitTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "git"
    }

    @Parameter(name: "C")
    var localRepositoryURL: URL? = nil

    @Flag(name: "tags", inversion: .prefixedNo, placement: .finalCommand)
    var tags: Bool? = nil

    @Flag(name: "force", placement: .finalCommand)
    var force: Bool = false

    @Flag(name: "verbose", placement: .selectedCommand)
    var verbose: Bool = false

    @Flag(name: "prune", placement: .finalCommand)
    var prune: Bool = false

    @Subcommand(of: ExampleGitTool.self, name: "push", command: push())
    var push

    @Subcommand(of: ExampleGitTool.self, name: "remote", command: remote())
    var remote

    final class push: AnyCommandLineTool, CommandLineTool {
        @Flag(name: "all")
        var pushAllBranches: Bool = false

        @Flag(name: "mirror")
        var mirrorAllRefs: Bool = false

        @Flag(name: "verify", inversion: .prefixedNo)
        var verify: Bool? = nil

        @Parameter(name: "signed")
        var signed: SignedPushRequestMode? = nil
    }

    final class remote: AnyCommandLineTool, CommandLineTool {
        @Subcommand(of: remote.self, name: "update", command: update())
        var update

        @Flag(name: "push", placement: .finalCommand)
        var push: Bool = false

        @Flag(name: "all", placement: .finalCommand)
        var all: Bool = false

        final class update: AnyCommandLineTool, CommandLineTool {

        }
    }
}

extension ExampleGitTool.push {
    enum SignedPushRequestMode: String, CLT.ArgumentValueConvertible {
        case always = "true"
        case never = "false"
        case ifAsked = "if-asked"
    }
}

#endif
