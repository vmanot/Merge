//
//  InvocationSummaryCondition.swift
//  Merge
//

import Foundation
import Swallow

public indirect enum InvocationSummaryCondition<Command: AnyCommandLineTool> {
    case predicate((InvocationSummaryContext<Command>) -> Bool)
    case not(InvocationSummaryCondition<Command>)
    case all([InvocationSummaryCondition<Command>])
    case any([InvocationSummaryCondition<Command>])
}

public struct InvocationSummaryValuePredicate<Value> {
    fileprivate let evaluate: (Value?) -> Bool

    fileprivate init(evaluate: @escaping (Value?) -> Bool) {
        self.evaluate = evaluate
    }

    public static var hasValue: Self {
        .init(evaluate: { value in
            guard let value else {
                return false
            }

            return _unwrapOptional(value) != nil
        })
    }

    public static func equalsTo(_ expected: Value) -> Self where Value: Equatable {
        .init(evaluate: { value in
            guard let value else {
                return false
            }

            return value == expected
        })
    }

    public static func satisfies(_ predicate: @escaping (Value) -> Bool) -> Self {
        .init(evaluate: { value in
            guard let value else {
                return false
            }

            return predicate(value)
        })
    }
}

extension InvocationSummaryCondition {
    public func evaluate(in context: InvocationSummaryContext<Command>) -> Bool {
        switch self {
            case .predicate(let predicate):
                return predicate(context)
            case .not(let condition):
                return !condition.evaluate(in: context)
            case .all(let conditions):
                return conditions.allSatisfy { $0.evaluate(in: context) }
            case .any(let conditions):
                return conditions.contains { $0.evaluate(in: context) }
        }
    }

    public func and(_ other: InvocationSummaryCondition<Command>) -> InvocationSummaryCondition<Command> {
        .all([self, other])
    }

    public func or(_ other: InvocationSummaryCondition<Command>) -> InvocationSummaryCondition<Command> {
        .any([self, other])
    }

    public func negated() -> InvocationSummaryCondition<Command> {
        .not(self)
    }

    public static func custom(
        _ condition: @escaping (InvocationSummaryContext<Command>) -> Bool
    ) -> InvocationSummaryCondition<Command> {
        .predicate(condition)
    }

    public static func value<Value: InvocationSummaryValue>(
        _ value: InvocationSummaryValueReference<Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value.WrappedValue>
    ) -> InvocationSummaryCondition<Command> {
        .predicate { context in
            predicate.evaluate(value.wrappedValue)
        }
    }
    
    public static func parentValue<Parent: AnyCommandLineTool, Value: InvocationSummaryValue>(
        _ value: InvocationSummaryValueFromParentCommandReference<Parent, Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value.WrappedValue>
    ) -> InvocationSummaryCondition<Command> {
        .predicate { context in
            guard let parent = context.parent(of: Parent.self) else {
                preconditionFailure("No such parent matched.")
            }
            return predicate.evaluate(parent[keyPath: value.keyPath].wrappedValue)
        }
    }

    public static prefix func !(
        condition: InvocationSummaryCondition<Command>
    ) -> InvocationSummaryCondition<Command> {
        .not(condition)
    }
}
