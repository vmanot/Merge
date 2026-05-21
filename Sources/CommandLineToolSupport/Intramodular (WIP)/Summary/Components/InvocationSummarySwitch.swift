//
// Copyright (c) Vatsal Manot
//

import Foundation
import Runtime
import Swallow

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolInvocationSummary {
    public protocol InvocationSummarySwitchCaseProtocol<Value> {
        associatedtype Command: AnyCommandLineTool
        associatedtype Value: InvocationSummaryValue
        associatedtype Summary: InvocationSummary where Summary.Command == Command

        @InvocationSummaryBuilder<Command>
        func summary(sourceValue: Value) throws -> Summary
    }

    enum InvocationSummarySwitchCaseError: Error {
        case caseNotMatch
        case noCaseMatched
        case notEquatable
    }

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

    @resultBuilder
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
            InvocationSummaryTupleCaseCondition((repeat each condition))
        }

        @_alwaysEmitIntoClient
        public static func buildBlock<each CaseCondition, DefaultSummary>(
            _ `default`: InvocationSummaryDefaultCaseCondition<Command, Value, DefaultSummary>,
            _ condition: repeat each CaseCondition,
        ) -> InvocationSummaryTupleCaseCondition<Command, Value, (repeat each CaseCondition, InvocationSummaryDefaultCaseCondition<Command, Value, DefaultSummary>)> where repeat each CaseCondition: InvocationSummarySwitchCaseProtocol, DefaultSummary: InvocationSummary, DefaultSummary.Command == Command {
            InvocationSummaryTupleCaseCondition((repeat each condition, `default`))
        }

        @_alwaysEmitIntoClient
        public static func buildExpression<Content>(
            _ content: Content
        ) -> Content where Content: InvocationSummarySwitchCaseProtocol, Content.Value == Value, Content.Command == Command {
            content
        }
    }

    public struct InvocationSummarySwitchCondition<Command: AnyCommandLineTool, Value: InvocationSummaryValue, CaseCondition: InvocationSummarySwitchCaseProtocol>: InvocationSummary where CaseCondition.Command == Command, CaseCondition.Value == Value {
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
        ) throws -> CommandLineToolInvocation.Arguments {
            let summary = try conditions.summary(sourceValue: command[keyPath: keyPath])

            return try summary.makeInvocationArguments(
                command: command,
                parent: parent,
                context: context
            )
        }
    }

    public struct InvocationSummaryTupleCaseCondition<Command: AnyCommandLineTool, Value: InvocationSummaryValue, ValueType>: InvocationSummarySwitchCaseProtocol {
        public var value: ValueType

        @inlinable public init(_ value: ValueType) {
            self.value = value
        }

        private var conditions: [any InvocationSummarySwitchCaseProtocol<Value>] {
            guard let metadata = TypeMetadata.Tuple(ValueType.self) else {
                return []
            }

            return metadata.fields.enumerated().map { index, field in
                guard let elementType = field.type.base as? any InvocationSummarySwitchCaseProtocol<Value>.Type else {
                    preconditionFailure("element type \(field.type.base) at index \(index) doesn't conform to InvocationSummarySwitchCaseProtocol.")
                }

                return withUnsafeBytes(of: value) { buffer in
                    func load<Condition: InvocationSummarySwitchCaseProtocol>(_: Condition.Type) -> Condition {
                        buffer.baseAddress!
                            .advanced(by: field.offset)
                            .load(as: Condition.self)
                    }

                    return load(elementType)
                }
            }
        }

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
