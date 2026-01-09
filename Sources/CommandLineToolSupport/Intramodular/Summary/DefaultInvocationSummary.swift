//
//  DefaultInvocationSummary.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

struct DefaultInvocationSummary<Command: AnyCommandLineTool>: InvocationSummary {
    init() { }
    
    func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [String] {
        try command
            .resolve().arguments
            .filter {
                !context.argumentIsRendered(command: command, argumentName: $0.id.rawValue)
            }
            .compactMap(\.invocationArgument)
    }
}
