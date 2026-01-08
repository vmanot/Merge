//
//  RuntimeReflectionInvocationSummary.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation

struct RuntimeReflectionInvocationSummary<Command: AnyCommandLineTool>: InvocationSummary {
    init() { }
    
    func makeInvocationArguments(
        context: InvocationSummaryContext<Command>
    ) throws -> [String] {
        try context.command
            .resolve().arguments
            .compactMap(\.invocationArgument)
    }
}
