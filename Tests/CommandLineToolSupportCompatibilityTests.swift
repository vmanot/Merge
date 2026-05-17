#if os(macOS)

import CommandLineToolSupport
import Testing

final class CompatibilityRootTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "root"
    }
    
    @Flag(name: "verbose", placement: .selectedCommand)
    var verbose: Bool = false
    
    @Flag(name: "force", placement: .finalCommand)
    var force: Bool = false
    
    @Parameter(name: nil, placement: .finalCommand)
    var path: String? = nil
    
    @Subcommand(of: CompatibilityRootTool.self, name: "leaf", command: CompatibilityLeafTool())
    var leaf
}

final class CompatibilityLeafTool: AnyCommandLineTool, CommandLineTool {
    override var _commandName: String {
        "leaf"
    }
}

final class OptionalParameterTool: AnyCommandLineTool, CommandLineTool {
    @Parameter
    var value: Any?
    
    override init() {
        
    }
}

@Suite
struct CommandLineToolSupportCompatibilityTests {
    @Test
    func placementAliasesPreserveArgumentPositionBehavior() throws {
        let command = try CompatibilityRootTool()
            .with(\.verbose, true)
            .with(\.force, true)
            .with(\.path, "Sources")
            .leaf
            .invocation
        
        #expect(command == "root leaf --verbose --force Sources")
    }
    
    @Test
    func structuredInvocationPreservesStringInvocation() throws {
        let command = CompatibilityRootTool()
            .with(\.force, true)
            .with(\.path, "Sources")
        
        let invocation = try command.commandInvocation
        
        #expect(invocation.components == ["root", "--force", "Sources"])
        #expect(invocation.commandName == "root")
        #expect(invocation.arguments == ["--force", "Sources"])
        #expect(invocation.commandLine == (try command.invocation))
        #expect(String(describing: invocation) == (try command.invocation))
    }
    
    @Test
    func oldPositionNamesRemainEquivalent() {
        #expect(CommandLineToolArgumentPlacement.declaringCommand == .local)
        #expect(CommandLineToolArgumentPlacement.selectedCommand == .nextCommand)
        #expect(CommandLineToolArgumentPlacement.finalCommand == .lastCommand)
    }
    
    @Test
    func optionalNonEquatableParametersCanBeModeled() throws {
        #expect(try OptionalParameterTool().invocation == "optionalparametertool")
    }
}

#endif
