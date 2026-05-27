#if os(macOS)

import CommandLineToolSupport
import Foundation

final class ExampleMiseTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "mise"
    }

    @Subcommand(of: ExampleMiseTool.self, name: "trust", command: Trust())
    var trust

    @Subcommand(of: ExampleMiseTool.self, name: "untrust", command: Untrust())
    var untrust

    @_SubcommandTool
    final class Trust: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "trust"
        }

        @Flag(name: "show")
        var show: Bool = false

        @Argument(name: nil)
        var path: String? = nil

        var invocationSummary: some InvocationSummary {
            Mode {
                ModeCase(\.$show, equals: true) {
                    \.$show
                }

                ModeCase(\.$path, .isPresent) {
                    \.$path
                }
            }
        }
    }

    @_SubcommandTool
    final class Untrust: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "untrust"
        }

        @Argument(name: nil)
        var path: String? = nil
    }
}

final class ExampleDirenvTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "direnv"
    }

    @Subcommand(of: ExampleDirenvTool.self, name: "allow", command: Allow())
    var allow

    @Subcommand(of: ExampleDirenvTool.self, name: "deny", command: Deny())
    var deny

    @_SubcommandTool
    final class Allow: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "allow"
        }

        @Argument(name: nil)
        var path: String? = nil
    }

    @_SubcommandTool
    final class Deny: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "deny"
        }

        @Argument(name: nil)
        var path: String? = nil
    }
}

final class ExampleSSHAddTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "ssh-add"
    }

    @Flag(conversion: .hyphenPrefixed, name: "l")
    var listIdentities: Bool = false

    @Flag(conversion: .hyphenPrefixed, name: "d")
    var deleteIdentity: Bool = false

    @Option(conversion: .hyphenPrefixed, name: "t")
    var lifetime: String? = nil

    @Flag(conversion: .hyphenPrefixed, name: "c")
    var confirmUse: Bool = false

    @Argument(name: nil)
    var identityPaths: [String] = []

    var invocationSummary: some InvocationSummary {
        Mode {
            ModeCase(\.$listIdentities, equals: true) {
                \.$listIdentities
            }

            ModeCase(\.$deleteIdentity, equals: true) {
                \.$deleteIdentity
                \.$identityPaths
            }

            ModeCase(
                InvocationSummaryCondition
                    .keyPath(\ExampleSSHAddTool.$identityPaths, .isPresent)
                    .and(!.keyPath(\ExampleSSHAddTool.$listIdentities, .equals(true)))
                    .and(!.keyPath(\ExampleSSHAddTool.$deleteIdentity, .equals(true)))
            ) {
                \.$lifetime
                \.$confirmUse
                \.$identityPaths
            }
        }
    }
}

final class ExampleDockerTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "docker"
    }

    @Subcommand(of: ExampleDockerTool.self, name: "login", command: Login())
    var login

    @Subcommand(of: ExampleDockerTool.self, name: "logout", command: Logout())
    var logout

    @_SubcommandTool
    final class Login: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "login"
        }

        @Argument(name: nil)
        var registry: String? = nil
    }

    @_SubcommandTool
    final class Logout: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "logout"
        }

        @Argument(name: nil)
        var registry: String? = nil
    }
}

final class ExampleKubectlTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "kubectl"
    }

    @Option(name: "kubeconfig", placement: .local)
    var kubeconfig: String? = nil

    @Subcommand(of: ExampleKubectlTool.self, name: "config", command: Config())
    var config

    @_SubcommandTool
    final class Config: AnyCommandLineTool, CommandLineTool {
        override var commandName: CommandLineTool.Name? {
            "config"
        }

        @Subcommand(of: Config.self, name: "use-context", command: UseContext())
        var useContext

        @Subcommand(of: Config.self, name: "current-context", command: CurrentContext())
        var currentContext

        @_SubcommandTool
        final class UseContext: AnyCommandLineTool, CommandLineTool {
            override var commandName: CommandLineTool.Name? {
                "use-context"
            }

            @Argument(name: nil)
            var contextName: String? = nil
        }

        @_SubcommandTool
        final class CurrentContext: AnyCommandLineTool, CommandLineTool {
            override var commandName: CommandLineTool.Name? {
                "current-context"
            }
        }
    }
}

final class ExampleXcodeSelectTool: AnyCommandLineTool, CommandLineTool {
    override var commandName: CommandLineTool.Name? {
        "xcode-select"
    }

    @Option(name: "switch")
    var developerDirectoryPath: String? = nil

    @Flag(name: "print-path")
    var printPath: Bool = false

    var invocationSummary: some InvocationSummary {
        Mode {
            ModeCase(\.$printPath, equals: true) {
                \.$printPath
            }

            ModeCase(\.$developerDirectoryPath, .isPresent) {
                \.$developerDirectoryPath
            }
        }
    }
}

#endif
