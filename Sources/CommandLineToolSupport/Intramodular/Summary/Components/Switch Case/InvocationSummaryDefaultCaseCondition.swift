//
//  InvocationSummaryDefaultCaseCondition.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/10.
//

import Foundation

public struct InvocationSummaryDefaultCaseCondition<Command: AnyCommandLineTool, Value: InvocationSummaryValue, Summary: InvocationSummary>: InvocationSummarySwitchCaseProtocol {
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
