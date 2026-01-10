//
//  InvocationSummaryCondition.swift
//  Merge
//

import Foundation
import Swallow

public indirect enum InvocationSummaryCondition<Command: AnyCommandLineTool> {
    case predicate((Command, AnyCommandLineTool?, InvocationSummaryContext) -> Bool)
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
            if let optional = value as? any OptionalProtocol {
                return !optional.isNil
            } else if let string = value as? String {
                return !string.isEmpty
            }
            
            return true
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
    public func evaluate(command: Command, parent: AnyCommandLineTool?, context: InvocationSummaryContext) -> Bool {
        switch self {
            case .predicate(let predicate):
                return predicate(command, parent, context)
            case .not(let condition):
                return !condition.evaluate(command: command, parent: parent, context: context)
            case .all(let conditions):
                return conditions.allSatisfy { $0.evaluate(command: command, parent: parent, context: context) }
            case .any(let conditions):
                return conditions.contains { $0.evaluate(command: command, parent: parent, context: context) }
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
        _ condition: @escaping (_ command: Command, _ parent: AnyCommandLineTool?, _ context: InvocationSummaryContext) -> Bool
    ) -> InvocationSummaryCondition<Command> {
        .predicate(condition)
    }

    public static func keyPath<Value: InvocationSummaryValue>(
        _ keyPath: KeyPath<Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value.WrappedValue>
    ) -> InvocationSummaryCondition<Command> {
        .predicate { command, _, context in
            predicate.evaluate(command[keyPath: keyPath].wrappedValue)
        }
    }
    
    public static func parentValue<Parent: AnyCommandLineTool, Value: InvocationSummaryValue>(
        _ value: InvocationSummaryValueReferenceFromParent<Parent, Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value.WrappedValue>
    ) -> InvocationSummaryCondition<Command> {
        .predicate { _, parent, context in
            let parent = parent as? Parent
            guard let parent else {
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
