//
//  DefaultInvocationSummary.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

extension CommandLineToolInvocationSummary {
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Fallback summary node that renders all unresolved/default arguments for a command.
public struct DefaultInvocationSummary<Command: AnyCommandLineTool>: InvocationSummary {
    @usableFromInline
    init() { }

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [String] {
        try command
            .resolve().arguments
            .filter {
                !context.argumentIsRendered(command: command, argumentName: $0.id.rawValue)
            }
            .flatMap { argument in
                defer {
                    context.registerArgument(command: command, argumentName: argument.id.rawValue)
                }

                return argument.invocationArguments
            }
    }
}

}

