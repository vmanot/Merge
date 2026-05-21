//
//  InvocationSummaryCaseCondition.swift
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
/// A branch candidate used by the invocation-summary `Switch` DSL.
public protocol InvocationSummarySwitchCaseProtocol<Value> {
    associatedtype Command: AnyCommandLineTool
    associatedtype Value: InvocationSummaryValue
    associatedtype Summary: InvocationSummary where Summary.Command == Command

    /// Returns the summary when source value equals to the branch.
    @InvocationSummaryBuilder<Command>
    func summary(sourceValue: Value) throws -> Summary
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Internal matching failure for provisional summary-switch lowering.
enum InvocationSummarySwitchCaseError: Error {
    case caseNotMatch
    case noCaseMatched
    case notEquatable
}

}

