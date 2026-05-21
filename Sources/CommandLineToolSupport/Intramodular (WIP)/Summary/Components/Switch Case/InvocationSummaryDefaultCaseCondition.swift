//
//  InvocationSummaryDefaultCaseCondition.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/10.
//

import Foundation

extension CommandLineToolInvocationSummary {
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Fallback summary-switch branch used when no value-specific case matches.
public struct InvocationSummaryDefaultCaseCondition<Command: AnyCommandLineTool, Value: InvocationSummaryValue, Summary: InvocationSummary>: InvocationSummarySwitchCaseProtocol where Summary.Command == Command {
    let summary: Summary

    public init(
        @InvocationSummaryBuilder<Command> _ content: () -> Summary
    ) {
        self.summary = content()
    }

    public func summary(sourceValue: Value) throws -> Summary {
        summary
    }
}

}

