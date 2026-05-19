#if os(macOS)
//
//  InvocationSummaryTupleCaseCondition.swift
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
/// Tuple-backed collection of switch branches produced by the case-condition result builder.
public struct InvocationSummaryTupleCaseCondition<Command: AnyCommandLineTool, Value: InvocationSummaryValue, ValueType>: InvocationSummarySwitchCaseProtocol {
    public var value: ValueType

    @inlinable public init(_ value: ValueType) {
        self.value = value
    }

    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    private var conditions: [any InvocationSummarySwitchCaseProtocol<Value>] {
        guard let metadata = TupleMetadata(ValueType.self) else { return [] }

        var conditions: [any InvocationSummarySwitchCaseProtocol<Value>] = []
        for i in 0 ..< metadata.elementCount {
            let element = metadata.element(at: Int(i))
            guard let elementType = element.type as? any InvocationSummarySwitchCaseProtocol<Value>.Type else {
                preconditionFailure("element type \(element.type) at index \(i) doesn't conform to InvocationSummarySwitchCaseProtocol.")
                continue
            }
            let condition = withUnsafeBytes(of: value) { buffer in
                func load<Condition: InvocationSummarySwitchCaseProtocol>(_: Condition.Type) -> Condition {
                    buffer.baseAddress!
                        .advanced(by: Int(element.offset))
                        .load(as: Condition.self)
                }

                return load(elementType)
            }
            conditions.append(condition)
        }

        return conditions
    }

    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func summary(sourceValue: Value) throws -> some InvocationSummary<Command> {
        guard let summary: any InvocationSummary<Command> = conditions.first(byUnwrapping: {
            (try? $0.summary(sourceValue: sourceValue)) as? (any InvocationSummary<Command>)
        }) else {
            throw InvocationSummarySwitchCaseError.noCaseMatched
        }

        return AnyInvocationSummary(erasing: summary)
    }
}

}

#endif
