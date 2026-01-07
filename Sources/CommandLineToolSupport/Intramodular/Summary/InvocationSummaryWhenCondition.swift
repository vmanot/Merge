//
//  InvocationSummaryWhenCondition.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation

public struct InvocationSummaryWhenCondition<Command: AnyCommandLineTool>: InvocationSummary {
    internal let condition: InvocationSummaryCondition<Command>
    internal let trueBranch: [InvocationSummaryComponent<Command>]
    internal let falseBranch: [InvocationSummaryComponent<Command>]?

    public init(
        _ condition: InvocationSummaryCondition<Command>,
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>]
    ) {
        self.condition = condition
        self.trueBranch = content()
        self.falseBranch = nil
    }

    public init(
        _ condition: InvocationSummaryCondition<Command>,
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>],
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> [InvocationSummaryComponent<Command>]
    ) {
        self.condition = condition
        self.trueBranch = content()
        self.falseBranch = elseContent()
    }

    public init(
        _ condition: @escaping (Command) -> Bool,
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>]
    ) {
        self.init(.predicate { context in
            condition(context.command)
        }, content)
    }
    
    public init(
        _ condition: @escaping (Command) -> Bool,
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>],
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> [InvocationSummaryComponent<Command>]
    ) {
        self.init(.predicate { context in
            condition(context.command)
        }, content, else: elseContent)
    }
    
    public init<Value>(
        _ value: InvocationSummaryValueExpression<Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value>,
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>]
    ) {
        self.init(.value(value, predicate), content)
    }
    
    public init<Value>(
        _ value: InvocationSummaryValueExpression<Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value>,
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>],
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> [InvocationSummaryComponent<Command>]
    ) {
        self.init(.value(value, predicate), content, else: elseContent)
    }
    
    public func makeInvocationArguments(
        context: InvocationSummaryContext<Command>
    ) throws -> [String] {
        let branch = condition.evaluate(in: context) ? trueBranch : (falseBranch ?? [])
        return branch.flatMap { $0.resolve(in: context) }
    }
}

extension InvocationSummaryWhenCondition {
    public init<Value>(
        _ keyPath: KeyPath<Command, InvocationSummaryValue<Value>>,
        _ predicate: InvocationSummaryValuePredicate<Value>,
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>]
    ) {
        self.init(.keyPath(keyPath), predicate, content)
    }
    
    public init<Value>(
        _ keyPath: KeyPath<Command, InvocationSummaryValue<Value>>,
        _ predicate: InvocationSummaryValuePredicate<Value>,
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>],
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> [InvocationSummaryComponent<Command>]
    ) {
        self.init(.keyPath(keyPath), predicate, content, else: elseContent)
    }
    
    public init<Value>(
        _ value: InvocationSummaryValue<Value>,
        _ predicate: InvocationSummaryValuePredicate<Value>,
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>]
    ) {
        self.init(.value(value), predicate, content)
    }
    
    public init<Value>(
        _ value: InvocationSummaryValue<Value>,
        _ predicate: InvocationSummaryValuePredicate<Value>,
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>],
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> [InvocationSummaryComponent<Command>]
    ) {
        self.init(.value(value), predicate, content, else: elseContent)
    }
    
    public init<Value: Equatable>(
        _ keyPath: KeyPath<Command, InvocationSummaryValue<Value>>,
        is expected: Value,
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>]
    ) {
        self.init(keyPath, .equalsTo(expected), content)
    }

    public init<Value: Equatable>(
        _ keyPath: KeyPath<Command, InvocationSummaryValue<Value>>,
        is expected: Value,
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>],
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> [InvocationSummaryComponent<Command>]
    ) {
        self.init(keyPath, .equalsTo(expected), content, else: elseContent)
    }

    public init<Value: Equatable>(
        _ value: InvocationSummaryValue<Value>,
        is expected: Value,
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>]
    ) {
        self.init(value, .equalsTo(expected), content)
    }

    public init<Value: Equatable>(
        _ value: InvocationSummaryValue<Value>,
        is expected: Value,
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>],
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> [InvocationSummaryComponent<Command>]
    ) {
        self.init(value, .equalsTo(expected), content, else: elseContent)
    }
}

public typealias When<Command: AnyCommandLineTool> = InvocationSummaryWhenCondition<Command>
