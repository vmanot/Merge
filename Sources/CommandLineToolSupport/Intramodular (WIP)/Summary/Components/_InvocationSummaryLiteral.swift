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
public struct _InvocationSummaryLiteral<Command: AnyCommandLineTool>: InvocationSummary {
    let text: String

    public init(text: String) {
        self.text = text
    }

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        CommandLineToolInvocation.Arguments([text])
    }
}

}
