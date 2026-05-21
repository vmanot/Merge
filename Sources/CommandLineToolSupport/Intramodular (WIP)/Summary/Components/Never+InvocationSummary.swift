//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension Never: CommandLineToolInvocationSummary.InvocationSummary {
    public typealias Command = AnyCommandLineTool

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        fatalError(.unavailable)
    }
}
