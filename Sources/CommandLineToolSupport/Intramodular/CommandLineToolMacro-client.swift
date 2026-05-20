#if os(macOS)
//
// Copyright (c) Vatsal Manot
//

@attached(extension, conformances: CommandLineTool, names: arbitrary)
public macro CommandLineTool() = #externalMacro(
    module: "CommandLineToolSupportMacros",
    type: "CommandLineToolMacro"
)

#endif
