//
//  RuntimeReflectionInvocationSummary.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation

struct RuntimeReflectionInvocationSummary: InvocationSummary {
    typealias Command = AnyCommandLineTool
    
    init() { }
    
    func makeInvocationArguments(
        context: InvocationSummaryContext<Command>
    ) throws -> [String] {
        try context.command._resolvedDescriptionChain
            .flatMap { descriptor -> [String] in
                let args = descriptor.arguments
                    .compactMap(\.invocationArgument)
                    .filter({ !$0.isEmpty })
                return [descriptor.toolName] + args
            }
    }
}
