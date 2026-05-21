//
// Copyright (c) Vatsal Manot
//


import Foundation
import Swallow

extension CommandLineToolInvocationSummary {
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Summary-switch branch that matches an equatable wrapped value.
public struct InvocationSummaryCaseCondition<Command: AnyCommandLineTool, Value: InvocationSummaryValue, Summary: InvocationSummary>: InvocationSummarySwitchCaseProtocol where Value.WrappedValue: Equatable, Summary.Command == Command {
    let value: Value.WrappedValue
    let summary: Summary

    public init(
        _ value: Value.WrappedValue,
        @InvocationSummaryBuilder<Command> _ content: () -> Summary
    ) {
        self.value = value
        self.summary = content()
    }

    public init(
        value: Value.WrappedValue,
        @InvocationSummaryBuilder<Command> _ content: () -> Summary
    ) {
        self.init(value, content)
    }

    public func summary(sourceValue: Value) throws -> Summary {
        guard sourceValue.wrappedValue.eraseToAnyEquatable() == value.eraseToAnyEquatable() else {
            throw InvocationSummarySwitchCaseError.caseNotMatch
        }

        return summary
    }
}

}

