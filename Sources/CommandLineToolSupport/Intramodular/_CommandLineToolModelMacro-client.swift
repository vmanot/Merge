#if os(macOS)
//
// Copyright (c) Vatsal Manot
//

@attached(member, names: named(_ExecutionRecord), named(_RawRunResult), named(_RunResult))
public macro _CommandLineToolModel() = #externalMacro(
    module: "CommandLineToolSupportMacros",
    type: "_CommandLineToolModelMacro"
)

#endif
