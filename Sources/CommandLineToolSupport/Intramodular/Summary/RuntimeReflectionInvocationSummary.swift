//
//  RuntimeReflectionInvocationSummary.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation

struct RuntimeReflectionInvocationSummary: InvocationSummary {
    init() { }
    
    func invocationArguments(for tool: AnyCommandLineTool) throws -> [String] {
        try tool._resolvedDescriptionChain
            .flatMap { descriptor -> [String] in
                var args = descriptor.arguments
                    .compactMap(\.invocationArgument)
                    .filter({ !$0.isEmpty })
                args.insert(descriptor.toolName, at: 0)
                return args
            }
    }
}
