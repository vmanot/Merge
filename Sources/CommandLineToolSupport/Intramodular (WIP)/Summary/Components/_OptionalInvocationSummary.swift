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
public struct _OptionalInvocationSummary<Command: AnyCommandLineTool, Content: InvocationSummary>: InvocationSummary where Content.Command == Command {
    let content: Content?

    public init(_ content: Content?) {
        self.content = content
    }

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        guard let content else {
            return []
        }

        return try content.makeInvocationArguments(
            command: command,
            parent: parent,
            context: context
        )
    }
}

}
