//
// Copyright (c) Vatsal Manot
//


import Foundation
import Swallow

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolInvocationSummary {
    /// Conditional summary node that renders one branch when a command/value predicate matches.
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
        
        @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
        public func makeInvocationArguments(
            command: Command,
            parent: AnyCommandLineTool?,
            context: InvocationSummaryContext
        ) throws -> CommandLineToolInvocation.Arguments {
            CommandLineToolInvocation.Arguments(
                try makeInvocationComponents(
                    command: command,
                    parent: parent,
                    context: context
                )
                .flatMap(\.argumentValues)
            )
        }
        
        @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
        public func makeInvocationComponents(
            command: Command,
            parent: AnyCommandLineTool?,
            context: InvocationSummaryContext
        ) throws -> [CommandLineToolInvocation.Component] {
            if try condition.evaluate(command: command, parent: parent, context: context) {
                return try trueBranch.makeInvocationComponents(
                    command: command,
                    parent: parent,
                    context: context
                )
            }
            
            return try falseBranch?.makeInvocationComponents(
                command: command,
                parent: parent,
                context: context
            ) ?? []
        }
    }
    
}

// MARK: - Self property reference

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolInvocationSummary.InvocationSummaryWhenCondition {
    public typealias Summary = CommandLineToolInvocationSummary.InvocationSummary
    public typealias SummaryValue = CommandLineToolInvocationSummary.InvocationSummaryValue
    public typealias ValuePredicate = CommandLineToolInvocationSummary.InvocationSummaryValuePredicate
    public typealias SummaryBuilder<BuilderCommand: AnyCommandLineTool> = CommandLineToolInvocationSummary.InvocationSummaryBuilder<BuilderCommand>
    
    public init<TrueContent: Summary, Value: SummaryValue>(
        _ value: KeyPath<Command, Value>,
        _ predicate: ValuePredicate<Value.WrappedValue>,
        @SummaryBuilder<Command> _ content: () -> TrueContent
    ) where TrueContent.Command == Command {
        self.init(.keyPath(value, predicate), content)
    }
    
    public init<TrueContent: Summary, FalseContent: Summary, Value: SummaryValue>(
        _ value: KeyPath<Command, Value>,
        _ predicate: ValuePredicate<Value.WrappedValue>,
        @SummaryBuilder<Command> _ content: () -> TrueContent,
        @SummaryBuilder<Command> `else` elseContent: () -> FalseContent
    ) where TrueContent.Command == Command, FalseContent.Command == Command {
        self.init(.keyPath(value, predicate), content, else: elseContent)
    }
    
    public init<TrueContent: Summary, Value: SummaryValue>(
        _ value: KeyPath<Command, Value>,
        is expected: Value.WrappedValue,
        @SummaryBuilder<Command> _ content: () -> TrueContent
    ) where Value.WrappedValue: Equatable, TrueContent.Command == Command {
        self.init(value, .equalsTo(expected), content)
    }
    
    public init<TrueContent: Summary, FalseContent: Summary, Value: SummaryValue>(
        _ value: KeyPath<Command, Value>,
        is expected: Value.WrappedValue,
        @SummaryBuilder<Command> _ content: () -> TrueContent,
        @SummaryBuilder<Command> `else` elseContent: () -> FalseContent
    ) where Value.WrappedValue: Equatable, TrueContent.Command == Command, FalseContent.Command == Command {
        self.init(value, .equalsTo(expected), content, else: elseContent)
    }
    
    public init<TrueContent: Summary, Value: SummaryValue>(
        _ value: KeyPath<Command, Value>,
        equals expected: Value.WrappedValue,
        @SummaryBuilder<Command> _ content: () -> TrueContent
    ) where Value.WrappedValue: Equatable, TrueContent.Command == Command {
        self.init(value, .equals(expected), content)
    }
    
    public init<TrueContent: Summary, FalseContent: Summary, Value: SummaryValue>(
        _ value: KeyPath<Command, Value>,
        equals expected: Value.WrappedValue,
        @SummaryBuilder<Command> _ content: () -> TrueContent,
        @SummaryBuilder<Command> `else` elseContent: () -> FalseContent
    ) where Value.WrappedValue: Equatable, TrueContent.Command == Command, FalseContent.Command == Command {
        self.init(value, .equals(expected), content, else: elseContent)
    }
}

// MARK: - Property reference to parent command

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolInvocationSummary.InvocationSummaryWhenCondition where Command: _InvocationSummarySubcommandWithParentCommand {
    public typealias ParentValueReference<Value> = CommandLineToolInvocationSummary.InvocationSummaryValueReferenceFromParent<Command.ParentCommand, Command, Value> where Value: SummaryValue
    
    public init<TrueContent: Summary, Value: SummaryValue>(
        _ value: ParentValueReference<Value>,
        _ predicate: ValuePredicate<Value.WrappedValue>,
        @SummaryBuilder<Command> _ content: () -> TrueContent
    ) where TrueContent.Command == Command {
        self.init(.parentValue(value, predicate), content)
    }
    
    public init<TrueContent: Summary, FalseContent: Summary, Value: SummaryValue>(
        _ value: ParentValueReference<Value>,
        _ predicate: ValuePredicate<Value.WrappedValue>,
        @SummaryBuilder<Command> _ content: () -> TrueContent,
        @SummaryBuilder<Command> `else` elseContent: () -> FalseContent
    ) where TrueContent.Command == Command, FalseContent.Command == Command {
        self.init(.parentValue(value, predicate), content, else: elseContent)
    }
    
    public init<TrueContent: Summary, Value: SummaryValue>(
        _ value: ParentValueReference<Value>,
        is expected: Value.WrappedValue,
        @SummaryBuilder<Command> _ content: () -> TrueContent
    ) where Value.WrappedValue: Equatable, TrueContent.Command == Command {
        self.init(value, .equalsTo(expected), content)
    }
    
    public init<TrueContent: Summary, FalseContent: Summary, Value: SummaryValue>(
        _ value: ParentValueReference<Value>,
        is expected: Value.WrappedValue,
        @SummaryBuilder<Command> _ content: () -> TrueContent,
        @SummaryBuilder<Command> `else` elseContent: () -> FalseContent
    ) where Value.WrappedValue: Equatable, TrueContent.Command == Command, FalseContent.Command == Command {
        self.init(value, .equalsTo(expected), content, else: elseContent)
    }
    
    public init<TrueContent: Summary, Value: SummaryValue>(
        _ value: ParentValueReference<Value>,
        equals expected: Value.WrappedValue,
        @SummaryBuilder<Command> _ content: () -> TrueContent
    ) where Value.WrappedValue: Equatable, TrueContent.Command == Command {
        self.init(value, .equals(expected), content)
    }
    
    public init<TrueContent: Summary, FalseContent: Summary, Value: SummaryValue>(
        _ value: ParentValueReference<Value>,
        equals expected: Value.WrappedValue,
        @SummaryBuilder<Command> _ content: () -> TrueContent,
        @SummaryBuilder<Command> `else` elseContent: () -> FalseContent
    ) where Value.WrappedValue: Equatable, TrueContent.Command == Command, FalseContent.Command == Command {
        self.init(value, .equals(expected), content, else: elseContent)
    }
}
