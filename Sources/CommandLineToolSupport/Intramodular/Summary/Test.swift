//
//  Test.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation

@available(macOS 11.0, *)
final class Swiftc: AnyCommandLineTool, CommandLineTool {
    @Parameter(name: "module-name")
    var moduleName: String? = nil

    @Flag(name: "emit-module-trace")
    var emitModuleTrace: Bool = false

    @Parameter(name: "emit-module-trace-path")
    var emitModuleTracePath: String? = nil

    @Parameter(name: nil)
    var inputs: [URL] = []

    @Parameter(name: "o")
    var output: URL? = nil

    var invocationSummary: some InvocationSummary {
        Summary {
            "swiftc"
            "-module-name"
            \.$moduleName

            if emitModuleTrace {
                "--emit-module-trace"
                "--emit-module-trace-path"
                \.$emitModuleTracePath
            }

            \.$inputs
            "-o"
            \.$output
        }
    }
}
