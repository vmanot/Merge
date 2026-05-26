//
// Copyright (c) Vatsal Manot
//

import MacroBuilder

@main
public struct module: CompilerPlugin {
    public let providingMacros: [Macro.Type] = [
        CommandLineToolMacro.self,
        _SubcommandToolMacro.self,
    ]

    public init() {

    }
}
