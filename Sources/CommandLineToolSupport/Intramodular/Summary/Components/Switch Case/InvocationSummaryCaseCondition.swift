//
//  InvocationSummaryCaseCondition.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/10.
//

import Foundation
import Swallow

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
        let source = sourceValue.wrappedValue as? any Equatable
        let target = value as? any Equatable
        guard let source, let target else { throw InvocationSummarySwitchCaseError.notEquatable }
        
        guard source.eraseToAnyEquatable() == target.eraseToAnyEquatable() else {
            throw InvocationSummarySwitchCaseError.caseNotMatch
        }
        
        return summary
    }
}
