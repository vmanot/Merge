#if os(macOS)
//
//  InvocationSummaryCaseCondition.swift
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
public struct InvocationSummaryCaseCondition<Command: AnyCommandLineTool, Value: InvocationSummaryValue, Summary: InvocationSummary>: InvocationSummarySwitchCaseProtocol {
    let value: Value.WrappedValue
    let summary: Summary

    public init(
        _ value: Value.WrappedValue,
        @InvocationSummaryBuilder<Command> _ content: () -> Summary
    ) {
        self.value = value
        self.summary = content()
    }
    
    public func summary(sourceValue: Value) throws -> Summary {
        guard sourceValue.wrappedValue.eraseToAnyEquatable() == value.eraseToAnyEquatable() else {
            throw InvocationSummarySwitchCaseError.caseNotMatch
        }
        
        return summary
    }
}

#endif
