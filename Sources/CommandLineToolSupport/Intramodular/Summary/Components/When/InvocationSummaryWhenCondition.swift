#if os(macOS)
//
//  InvocationSummaryWhenCondition.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct InvocationSummaryWhenCondition<Command: AnyCommandLineTool>: InvocationSummary {
    internal let condition: InvocationSummaryCondition<Command>
    internal let trueBranch: any InvocationSummary<Command>
    internal let falseBranch: (any InvocationSummary<Command>)?
    
    public init<TrueContent: InvocationSummary>(
        _ condition: InvocationSummaryCondition<Command>,
        @InvocationSummaryBuilder<Command> _ content: () -> TrueContent
    ) where TrueContent.Command == Command {
        self.condition = condition
        self.trueBranch = content()
        self.falseBranch = nil
    }
    
    public init<TrueContent: InvocationSummary, FalseContent: InvocationSummary>(
        _ condition: InvocationSummaryCondition<Command>,
        @InvocationSummaryBuilder<Command> _ content: () -> TrueContent,
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> FalseContent
    ) where TrueContent.Command == Command, FalseContent.Command == Command {
        self.condition = condition
        self.trueBranch = content()
        self.falseBranch = elseContent()
    }
    
    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [String] {
        if condition.evaluate(command: command, parent: parent, context: context) {
            return try trueBranch.makeInvocationArguments(
                command: command,
                parent: parent,
                context: context
            )
        }
        
        return try falseBranch?.makeInvocationArguments(
            command: command,
            parent: parent,
            context: context
        ) ?? []
    }
}

// MARK: - Self property reference

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension InvocationSummaryWhenCondition {
    public init<TrueContent: InvocationSummary, Value: InvocationSummaryValue>(
        _ value: KeyPath<Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value.WrappedValue>,
        @InvocationSummaryBuilder<Command> _ content: () -> TrueContent
    ) where TrueContent.Command == Command {
        self.init(.keyPath(value, predicate), content)
    }
    
    public init<TrueContent: InvocationSummary, FalseContent: InvocationSummary, Value: InvocationSummaryValue>(
        _ value: KeyPath<Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value.WrappedValue>,
        @InvocationSummaryBuilder<Command> _ content: () -> TrueContent,
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> FalseContent
    ) where TrueContent.Command == Command, FalseContent.Command == Command {
        self.init(.keyPath(value, predicate), content, else: elseContent)
    }
    
    public init<TrueContent: InvocationSummary, Value: InvocationSummaryValue>(
        _ value: KeyPath<Command, Value>,
        is expected: Value.WrappedValue,
        @InvocationSummaryBuilder<Command> _ content: () -> TrueContent
    ) where Value.WrappedValue: Equatable, TrueContent.Command == Command {
        self.init(value, .equalsTo(expected), content)
    }
    
    public init<TrueContent: InvocationSummary, FalseContent: InvocationSummary, Value: InvocationSummaryValue>(
        _ value: KeyPath<Command, Value>,
        is expected: Value.WrappedValue,
        @InvocationSummaryBuilder<Command> _ content: () -> TrueContent,
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> FalseContent
    ) where Value.WrappedValue: Equatable, TrueContent.Command == Command, FalseContent.Command == Command {
        self.init(value, .equalsTo(expected), content, else: elseContent)
    }
}

// MARK: - Property reference to parent command

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension InvocationSummaryWhenCondition {
    public init<Parent: AnyCommandLineTool, TrueContent: InvocationSummary, Value: InvocationSummaryValue>(
        _ value: InvocationSummaryValueReferenceFromParent<Parent, Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value.WrappedValue>,
        @InvocationSummaryBuilder<Command> _ content: () -> TrueContent
    ) where TrueContent.Command == Command {
        self.init(.parentValue(value, predicate), content)
    }
    
    public init<Parent: AnyCommandLineTool, TrueContent: InvocationSummary, FalseContent: InvocationSummary, Value: InvocationSummaryValue>(
        _ value: InvocationSummaryValueReferenceFromParent<Parent, Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value.WrappedValue>,
        @InvocationSummaryBuilder<Command> _ content: () -> TrueContent,
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> FalseContent
    ) where TrueContent.Command == Command, FalseContent.Command == Command {
        self.init(.parentValue(value, predicate), content, else: elseContent)
    }
    
    public init<Parent: AnyCommandLineTool, TrueContent: InvocationSummary, Value: InvocationSummaryValue>(
        _ value: InvocationSummaryValueReferenceFromParent<Parent, Command, Value>,
        is expected: Value.WrappedValue,
        @InvocationSummaryBuilder<Command> _ content: () -> TrueContent
    ) where Value.WrappedValue: Equatable, TrueContent.Command == Command {
        self.init(value, .equalsTo(expected), content)
    }

    public init<Parent: AnyCommandLineTool, TrueContent: InvocationSummary, FalseContent: InvocationSummary, Value: InvocationSummaryValue>(
        _ value: InvocationSummaryValueReferenceFromParent<Parent, Command, Value>,
        is expected: Value.WrappedValue,
        @InvocationSummaryBuilder<Command> _ content: () -> TrueContent,
        @InvocationSummaryBuilder<Command> `else` elseContent: () -> FalseContent
    ) where Value.WrappedValue: Equatable, TrueContent.Command == Command, FalseContent.Command == Command {
        self.init(value, .equalsTo(expected), content, else: elseContent)
    }
}

#endif
