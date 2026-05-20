#if os(macOS)
//
// Copyright (c) Vatsal Manot
//

@attached(member, names: named(commandName))
@attached(extension, conformances: CommandLineTool, names: arbitrary)
public macro CommandLineTool() = #externalMacro(
    module: "CommandLineToolSupportMacros",
    type: "CommandLineToolMacro"
)

@attached(member, names: named(commandName))
@attached(extension, conformances: CommandLineTool, names: arbitrary)
public macro CommandLineTool(
    _ name: String
) = #externalMacro(
    module: "CommandLineToolSupportMacros",
    type: "CommandLineToolMacro"
)

@attached(member, names: named(commandName))
@attached(extension, conformances: CommandLineTool, names: arbitrary)
public macro CommandLineTool(
    name: String
) = #externalMacro(
    module: "CommandLineToolSupportMacros",
    type: "CommandLineToolMacro"
)

@attached(member, names: named(commandName))
@attached(extension, conformances: CommandLineTool, names: arbitrary)
public macro CommandLineTool(
    _ name: CommandLineTool.Name
) = #externalMacro(
    module: "CommandLineToolSupportMacros",
    type: "CommandLineToolMacro"
)

@attached(member, names: named(commandName))
@attached(extension, conformances: CommandLineTool, names: arbitrary)
public macro CommandLineTool(
    name: CommandLineTool.Name
) = #externalMacro(
    module: "CommandLineToolSupportMacros",
    type: "CommandLineToolMacro"
)

public typealias _CommandLineTool_Name = CommandLineToolName

#endif
