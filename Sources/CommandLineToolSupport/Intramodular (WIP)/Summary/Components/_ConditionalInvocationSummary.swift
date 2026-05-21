//
// Copyright (c) Vatsal Manot
//

import Foundation

extension CommandLineToolInvocationSummary {
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public enum _ConditionalInvocationSummary<Command: AnyCommandLineTool, TrueContent: InvocationSummary, FalseContent: InvocationSummary>: InvocationSummary where TrueContent.Command == Command, FalseContent.Command == Command {
    case first(TrueContent)
    case second(FalseContent)

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        switch self {
            case .first(let content):
                return try content.makeInvocationArguments(
                    command: command,
                    parent: parent,
                    context: context
                )
            case .second(let content):
                return try content.makeInvocationArguments(
                    command: command,
                    parent: parent,
                    context: context
                )
        }
    }
}

}
