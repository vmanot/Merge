//
//  InvocationSummaryWhenCondition.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

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
        _ condition: @escaping (Command, InvocationSummaryContext) -> Bool,
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>]
    ) {
        self.init(.predicate { command, context in
            condition(command, context)
        }, content)
    }
    
    public init(
        _ condition: @escaping (Command, InvocationSummaryContext) -> Bool,
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>],
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> [any InvocationSummary<Command>]
    ) {
        self.init(.predicate { command, context in
            condition(command, context)
        }, content, else: elseContent)
    }
    
    public init<Value: InvocationSummaryValue>(
        _ value: KeyPath<Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value.WrappedValue>,
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>]
    ) {
        self.init(.keyPath(value, predicate), content)
    }
    
    public init<Value: InvocationSummaryValue>(
        _ value: KeyPath<Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value.WrappedValue>,
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>],
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> [any InvocationSummary<Command>]
    ) {
        self.init(.keyPath(value, predicate), content, else: elseContent)
    }
    
    public init<Value: InvocationSummaryValue>(
        _ value: KeyPath<Command, Value>,
        is expected: Value.WrappedValue,
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>]
    ) where Value.WrappedValue : Equatable {
        self.init(value, .equalsTo(expected), content)
    }

    public init<Value: InvocationSummaryValue>(
        _ value: KeyPath<Command, Value>,
        is expected: Value.WrappedValue,
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>],
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> [any InvocationSummary<Command>]
    ) where Value.WrappedValue : Equatable {
        self.init(value, .equalsTo(expected), content, else: elseContent)
    }
    
    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [String] {
        let branch: [any InvocationSummary<Command>] = condition.evaluate(command: command, context: context) ? trueBranch : (falseBranch ?? [])
        return try branch.flatMap({
            try $0.makeInvocationArguments(command: command, parent: parent, context: context)
        })
    }
}
