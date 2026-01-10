//
//  InvocationSummaryCaseCondition.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/10.
//

import Foundation
import Swallow

public protocol InvocationSummarySwitchCaseProtocol<Value> {
    associatedtype Command: AnyCommandLineTool
    associatedtype Value: InvocationSummaryValue
    associatedtype Summary: InvocationSummary where Summary.Command == Command
    
    /// Returns the summary when source value equals to the branch.
    @InvocationSummaryBuilder<Command>
    func summary(sourceValue: Value) throws -> Summary
}

enum InvocationSummarySwitchCaseError: Error {
    case caseNotMatch
    case notEquatable
}
