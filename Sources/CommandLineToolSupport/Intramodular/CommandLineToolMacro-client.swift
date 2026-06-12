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

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@attached(member, names: named(commandName))
@attached(extension, conformances: CommandLineTool, names: arbitrary)
public macro CommandLineTool(
    _ name: CommandLineTool.Name
) = #externalMacro(
    module: "CommandLineToolSupportMacros",
    type: "CommandLineToolMacro"
)

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@attached(member, names: named(commandName))
@attached(extension, conformances: CommandLineTool, names: arbitrary)
public macro CommandLineTool(
    name: CommandLineTool.Name
) = #externalMacro(
    module: "CommandLineToolSupportMacros",
    type: "CommandLineToolMacro"
)

@attached(peer)
@attached(member, names: named(ParentCommand))
@attached(extension, conformances: CommandLineTool, _InvocationSummarySubcommandWithParentCommand, names: arbitrary)
public macro _SubcommandTool() = #externalMacro(
    module: "CommandLineToolSupportMacros",
    type: "_SubcommandToolMacro"
)

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public typealias _CommandLineTool_Name = CommandLineToolName
