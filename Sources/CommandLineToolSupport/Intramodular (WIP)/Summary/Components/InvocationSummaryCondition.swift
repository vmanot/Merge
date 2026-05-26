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
/// Boolean predicate tree used by `When` summary nodes.
public indirect enum InvocationSummaryCondition<Command: AnyCommandLineTool> {
    case predicate((Command, AnyCommandLineTool?, InvocationSummaryContext) throws -> Bool)
    case not(InvocationSummaryCondition<Command>)
    case all([InvocationSummaryCondition<Command>])
    case any([InvocationSummaryCondition<Command>])
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Reusable predicate over a property-wrapper value referenced from an invocation summary.
public struct InvocationSummaryValuePredicate<Value> {
    fileprivate let evaluate: (Value?) -> Bool

    fileprivate init(evaluate: @escaping (Value?) -> Bool) {
        self.evaluate = evaluate
    }

    private static func containsValue(_ value: Any?) -> Bool {
        guard let value else {
            return false
        }

        let mirror = Mirror(reflecting: value)

        if mirror.displayStyle == .optional {
            guard let child = mirror.children.first else {
                return false
            }

            return containsValue(child.value)
        }

        if let string = value as? String {
            return !string.isEmpty
        }

        if mirror.displayStyle == .collection || mirror.displayStyle == .set || mirror.displayStyle == .dictionary {
            return !mirror.children.isEmpty
        }

        return true
    }

    public static var hasValue: Self {
        .init(evaluate: containsValue)
    }

    public static var isPresent: Self {
        hasValue
    }

    public static func equalsTo(_ expected: Value) -> Self where Value: Equatable {
        .init(evaluate: { value in
            guard let value else {
                return false
            }

            return value == expected
        })
    }

    public static func equals(_ expected: Value) -> Self where Value: Equatable {
        equalsTo(expected)
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

}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolInvocationSummary.InvocationSummaryCondition {
    public func evaluate(command: Command, parent: AnyCommandLineTool?, context: CommandLineToolInvocationSummary.InvocationSummaryContext) throws -> Bool {
        switch self {
            case .predicate(let predicate):
                return try predicate(command, parent, context)
            case .not(let condition):
                return try !condition.evaluate(command: command, parent: parent, context: context)
            case .all(let conditions):
                for condition in conditions {
                    guard try condition.evaluate(command: command, parent: parent, context: context) else {
                        return false
                    }
                }

                return true
            case .any(let conditions):
                for condition in conditions {
                    if try condition.evaluate(command: command, parent: parent, context: context) {
                        return true
                    }
                }

                return false
        }
    }

    public func and(_ other: CommandLineToolInvocationSummary.InvocationSummaryCondition<Command>) -> CommandLineToolInvocationSummary.InvocationSummaryCondition<Command> {
        .all([self, other])
    }

    public func or(_ other: CommandLineToolInvocationSummary.InvocationSummaryCondition<Command>) -> CommandLineToolInvocationSummary.InvocationSummaryCondition<Command> {
        .any([self, other])
    }

    public func negated() -> CommandLineToolInvocationSummary.InvocationSummaryCondition<Command> {
        .not(self)
    }

    public static func custom(
        _ condition: @escaping (_ command: Command, _ parent: AnyCommandLineTool?, _ context: CommandLineToolInvocationSummary.InvocationSummaryContext) throws -> Bool
    ) -> CommandLineToolInvocationSummary.InvocationSummaryCondition<Command> {
        .predicate(condition)
    }

    public static var always: CommandLineToolInvocationSummary.InvocationSummaryCondition<Command> {
        .predicate { _, _, _ in true }
    }

    public static var never: CommandLineToolInvocationSummary.InvocationSummaryCondition<Command> {
        .predicate { _, _, _ in false }
    }

    public static func keyPath<Value: CommandLineToolInvocationSummary.InvocationSummaryValue>(
        _ keyPath: KeyPath<Command, Value>,
        _ predicate: CommandLineToolInvocationSummary.InvocationSummaryValuePredicate<Value.WrappedValue>
    ) -> CommandLineToolInvocationSummary.InvocationSummaryCondition<Command> {
        .predicate { command, _, context in
            predicate.evaluate(command[keyPath: keyPath].wrappedValue)
        }
    }

    public static func contextValue<Value>(
        _ type: Value.Type = Value.self,
        _ predicate: CommandLineToolInvocationSummary.InvocationSummaryValuePredicate<Value>
    ) -> CommandLineToolInvocationSummary.InvocationSummaryCondition<Command> {
        .predicate { _, _, context in
            predicate.evaluate(context.value(for: type))
        }
    }

    public static func parentValue<Parent: AnyCommandLineTool, Value: CommandLineToolInvocationSummary.InvocationSummaryValue>(
        _ value: CommandLineToolInvocationSummary.InvocationSummaryValueReferenceFromParent<Parent, Command, Value>,
        _ predicate: CommandLineToolInvocationSummary.InvocationSummaryValuePredicate<Value.WrappedValue>
    ) -> CommandLineToolInvocationSummary.InvocationSummaryCondition<Command> {
        .predicate { _, parent, context in
            let actualParent = parent

            guard let parent = parent as? Parent else {
                throw CommandLineToolInvocationSummary.Error.missingExpectedParent(
                    command: Command.self,
                    expectedParent: Parent.self,
                    actualParent: actualParent.map { Swift.type(of: $0) },
                    location: nil
                )
            }
            return predicate.evaluate(parent[keyPath: value.keyPath].wrappedValue)
        }
    }

    public static prefix func !(
        condition: CommandLineToolInvocationSummary.InvocationSummaryCondition<Command>
    ) -> CommandLineToolInvocationSummary.InvocationSummaryCondition<Command> {
        .not(condition)
    }
}
