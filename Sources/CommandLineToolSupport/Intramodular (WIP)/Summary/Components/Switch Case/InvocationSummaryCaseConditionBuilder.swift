#if os(macOS)
//
//  InvocationSummaryCaseConditionBuilder.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/10.
//

import Foundation

extension CommandLineToolInvocationSummary {
@resultBuilder
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Result builder for provisional summary-switch case lists.
public struct InvocationSummaryCaseConditionBuilder<Command: AnyCommandLineTool, Value: InvocationSummaryValue> {
    @_alwaysEmitIntoClient
    public static func buildBlock<Content>(
        _ content: Content
    ) -> Content where Content: InvocationSummarySwitchCaseProtocol, Content.Value == Value, Content.Command == Command {
        content
    }

    @_disfavoredOverload
    @_alwaysEmitIntoClient
    public static func buildBlock<each CaseCondition>(
        _ condition: repeat each CaseCondition
    ) -> InvocationSummaryTupleCaseCondition<Command, Value, (repeat each CaseCondition)> where repeat each CaseCondition: InvocationSummarySwitchCaseProtocol {
        InvocationSummaryTupleCaseCondition(
            (repeat each condition)
        )
    }

    @_alwaysEmitIntoClient
    public static func buildBlock<each CaseCondition, DefaultSummary>(
        _ `default`: InvocationSummaryDefaultCaseCondition<Command, Value, DefaultSummary>,
        _ condition: repeat each CaseCondition,
    ) -> InvocationSummaryTupleCaseCondition<Command, Value, (repeat each CaseCondition, InvocationSummaryDefaultCaseCondition<Command, Value, DefaultSummary>)> where repeat each CaseCondition: InvocationSummarySwitchCaseProtocol, DefaultSummary: InvocationSummary, DefaultSummary.Command == Command {
        InvocationSummaryTupleCaseCondition(
            (repeat each condition, `default`)
        )
    }

    @_alwaysEmitIntoClient
    public static func buildExpression<Content>(
        _ content: Content
    ) -> Content where Content: InvocationSummarySwitchCaseProtocol, Content.Value == Value, Content.Command == Command {
        content
    }
}

}

#endif
