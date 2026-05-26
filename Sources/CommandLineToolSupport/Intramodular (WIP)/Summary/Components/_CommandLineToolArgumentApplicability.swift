//
// Copyright (c) Vatsal Manot
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct _CommandLineToolArgumentApplicability<Command: AnyCommandLineTool> {
    public enum Otherwise: Hashable, Sendable {
        case omit(reason: String?)
        case unavailable(reason: String?)
    }

    public var condition: CommandLineToolInvocationSummary.InvocationSummaryCondition<Command>
    public var otherwise: Otherwise

    public init(
        when condition: CommandLineToolInvocationSummary.InvocationSummaryCondition<Command>,
        otherwise: Otherwise
    ) {
        self.condition = condition
        self.otherwise = otherwise
    }
}
