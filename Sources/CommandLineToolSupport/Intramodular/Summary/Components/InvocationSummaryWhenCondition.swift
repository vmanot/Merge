//
//  InvocationSummaryWhenCondition.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

public typealias When<Command: AnyCommandLineTool> = InvocationSummaryWhenCondition<Command>

public struct InvocationSummaryWhenCondition<Command: AnyCommandLineTool>: InvocationSummary {
    internal let condition: InvocationSummaryCondition<Command>
    internal let trueBranch: [any InvocationSummary<Command>]
    internal let falseBranch: [any InvocationSummary<Command>]?

    public init(
        _ condition: InvocationSummaryCondition<Command>,
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>]
    ) {
        self.condition = condition
        self.trueBranch = content()
        self.falseBranch = nil
    }

    public init(
        _ condition: InvocationSummaryCondition<Command>,
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>],
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> [any InvocationSummary<Command>]
    ) {
        self.condition = condition
        self.trueBranch = content()
        self.falseBranch = elseContent()
    }

    public init(
        _ condition: @escaping (Command) -> Bool,
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>]
    ) {
        self.init(.predicate { context in
            condition(context.command)
        }, content)
    }
    
    public init(
        _ condition: @escaping (Command) -> Bool,
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>],
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> [any InvocationSummary<Command>]
    ) {
        self.init(.predicate { context in
            condition(context.command)
        }, content, else: elseContent)
    }
    
    public init<Value: InvocationSummaryValue>(
        _ value: InvocationSummaryValueReference<Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value.WrappedValue>,
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>]
    ) {
        self.init(.value(value, predicate), content)
    }
    
    public init<Value: InvocationSummaryValue>(
        _ value: InvocationSummaryValueReference<Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value.WrappedValue>,
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>],
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> [any InvocationSummary<Command>]
    ) {
        self.init(.value(value, predicate), content, else: elseContent)
    }
    
    public init<Value: InvocationSummaryValue>(
        _ value: InvocationSummaryValueReference<Command, Value>,
        is expected: Value.WrappedValue,
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>]
    ) where Value.WrappedValue : Equatable {
        self.init(value, .equalsTo(expected), content)
    }

    public init<Value: InvocationSummaryValue>(
        _ value: InvocationSummaryValueReference<Command, Value>,
        is expected: Value.WrappedValue,
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>],
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> [any InvocationSummary<Command>]
    ) where Value.WrappedValue : Equatable {
        self.init(value, .equalsTo(expected), content, else: elseContent)
    }
    
    public func makeInvocationArguments(context: InvocationSummaryContext<Command>) throws -> [String] {
        let branch: [any InvocationSummary<Command>] = condition.evaluate(in: context) ? trueBranch : (falseBranch ?? [])
        return try branch.flatMap({
            try $0.makeInvocationArguments(context: context)
        })
    }
}
