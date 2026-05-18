//
// Copyright (c) Vatsal Manot
//

import MacroBuilder

@main
public struct module: CompilerPlugin {
    public let providingMacros: [Macro.Type] = [
        _CommandLineToolModelMacro.self,
    ]

    public init() {

    }
}

