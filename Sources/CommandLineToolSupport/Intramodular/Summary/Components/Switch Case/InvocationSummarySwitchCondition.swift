#if os(macOS)
//
//  InvocationSummarySwitchCondition.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/10.
//

import Foundation
import Swallow

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct InvocationSummarySwitchCondition<Command: AnyCommandLineTool, Value: InvocationSummaryValue, CaseCondition: InvocationSummarySwitchCaseProtocol>: InvocationSummary {
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
    ) throws -> [String] {
        let summary = try conditions.summary(sourceValue: command[keyPath: keyPath] as! CaseCondition.Value)
        
        let value = try summary.makeInvocationArguments(
            command: command as! CaseCondition.Command,
            parent: parent,
            context: context
        )
        return value
    }
}

#endif
