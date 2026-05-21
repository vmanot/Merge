//
//  InvocationSummarySwitchCondition.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/10.
//

import Foundation
import Swallow

extension CommandLineToolInvocationSummary {
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Switch-style summary node that chooses a branch based on one property-wrapper value.
public struct InvocationSummarySwitchCondition<Command: AnyCommandLineTool, Value: InvocationSummaryValue, CaseCondition: InvocationSummarySwitchCaseProtocol>: InvocationSummary where CaseCondition.Command == Command, CaseCondition.Value == Value {
    private let keyPath: KeyPath<Command, Value>
    private let conditions: CaseCondition

    public init(
        _ value: KeyPath<Command, Value>,
        @InvocationSummaryCaseConditionBuilder<Command, Value> _ conditions: () -> CaseCondition
    ) {
        self.keyPath = value
        self.conditions = conditions()
    }

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        let summary = try conditions.summary(sourceValue: command[keyPath: keyPath])

        return try summary.makeInvocationArguments(
            command: command,
            parent: parent,
            context: context
        )
    }
}

}
