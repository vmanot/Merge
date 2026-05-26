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
@resultBuilder
/// Result builder that turns summary literals, value references, and conditional nodes into a summary tree.
public struct InvocationSummaryBuilder<Command: AnyCommandLineTool> {
    @_alwaysEmitIntoClient
    public static func buildBlock() -> _EmptyInvocationSummary<Command> {
        _EmptyInvocationSummary()
    }

    @_alwaysEmitIntoClient
    public static func buildBlock<Content>(
        _ content: Content
    ) -> Content where Content: InvocationSummary {
        content
    }

    @_disfavoredOverload
    @_alwaysEmitIntoClient
    public static func buildBlock<each Content>(
        _ content: repeat each Content
    ) -> TupleInvocationSummary<Command, (repeat each Content)> where repeat each Content: InvocationSummary {
        TupleInvocationSummary((repeat each content))
    }

    @_alwaysEmitIntoClient
    public static func buildExpression<Content>(
        _ content: Content
    ) -> Content where Content: InvocationSummary{
        content
    }

    @available(*, unavailable, message: "this expression does not conform to 'InvocationSummary'")
    @_disfavoredOverload
    @_alwaysEmitIntoClient
    public static func buildExpression(_ invalid: Any) -> some InvocationSummary {
        fatalError()
    }

    @_alwaysEmitIntoClient
    public static func buildExpression(
        _ expression: String
    ) -> _InvocationSummaryLiteral<Command> {
        _InvocationSummaryLiteral(text: expression)
    }

    @_alwaysEmitIntoClient
    public static func buildExpression<Value>(
        _ expression: KeyPath<Command, _CommandLineToolFlag<Value>>
    ) -> InvocationSummaryValueReference<Command, _CommandLineToolFlag<Value>> {
        InvocationSummaryValueReference(keyPath: expression)
    }

    @_alwaysEmitIntoClient
    public static func buildExpression<Value>(
        _ expression: KeyPath<Command, _CommandLineToolParameter<Value>>
    ) -> InvocationSummaryValueReference<Command, _CommandLineToolParameter<Value>> {
        InvocationSummaryValueReference(keyPath: expression)
    }

    @_alwaysEmitIntoClient
    public static func buildOptional<Content>(
        _ component: Content?
    ) -> _OptionalInvocationSummary<Command, Content> where Content: InvocationSummary, Content.Command == Command {
        _OptionalInvocationSummary(component)
    }

    @_alwaysEmitIntoClient
    public static func buildEither<TrueContent, FalseContent>(
        first component: TrueContent
    ) -> _ConditionalInvocationSummary<Command, TrueContent, FalseContent> where TrueContent: InvocationSummary, FalseContent: InvocationSummary,
          TrueContent.Command == Command, FalseContent.Command == Command {
        _ConditionalInvocationSummary.first(component)
    }

    @_alwaysEmitIntoClient
    public static func buildEither<TrueContent, FalseContent>(
        second component: FalseContent
    ) -> _ConditionalInvocationSummary<Command, TrueContent, FalseContent> where TrueContent: InvocationSummary, FalseContent: InvocationSummary,
          TrueContent.Command == Command, FalseContent.Command == Command {
        _ConditionalInvocationSummary.second(component)
    }

    @_alwaysEmitIntoClient
    public static func buildLimitedAvailability<Content>(
        _ component: Content
    ) -> Content where Content: InvocationSummary, Content.Command == Command {
        component
    }
}

public struct _EmptyInvocationSummary<Command: AnyCommandLineTool>: InvocationSummary {
    @inlinable public init() { }

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        []
    }

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        []
    }
}

public struct _InvocationSummaryLiteral<Command: AnyCommandLineTool>: InvocationSummary {
    let text: String

    public init(text: String) {
        self.text = text
    }

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        CommandLineToolInvocation.Arguments([text])
    }

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        text.isEmpty ? [] : [.positionalArgument(CommandLineToolInvocation.Argument(text))]
    }
}

public struct _OptionalInvocationSummary<Command: AnyCommandLineTool, Content: InvocationSummary>: InvocationSummary where Content.Command == Command {
    let content: Content?

    public init(_ content: Content?) {
        self.content = content
    }

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        guard let content else {
            return []
        }

        return try content.makeInvocationArguments(
            command: command,
            parent: parent,
            context: context
        )
    }

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        guard let content else {
            return []
        }

        return try content.makeInvocationComponents(
            command: command,
            parent: parent,
            context: context
        )
    }
}

public enum _ConditionalInvocationSummary<Command: AnyCommandLineTool, TrueContent: InvocationSummary, FalseContent: InvocationSummary>: InvocationSummary where TrueContent.Command == Command, FalseContent.Command == Command {
    case first(TrueContent)
    case second(FalseContent)

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        switch self {
            case .first(let content):
                return try content.makeInvocationArguments(
                    command: command,
                    parent: parent,
                    context: context
                )
            case .second(let content):
                return try content.makeInvocationArguments(
                    command: command,
                    parent: parent,
                    context: context
                )
        }
    }

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        switch self {
            case .first(let content):
                return try content.makeInvocationComponents(
                    command: command,
                    parent: parent,
                    context: context
                )
            case .second(let content):
                return try content.makeInvocationComponents(
                    command: command,
                    parent: parent,
                    context: context
                )
        }
    }
}

/// Fallback summary node that renders all unresolved/default arguments for a command.
public struct DefaultInvocationSummary<Command: AnyCommandLineTool>: InvocationSummary {
    @usableFromInline
    init() { }

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

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        try command
            .resolve().arguments
            .filter {
                !context.argumentIsHandled(command: command, argumentName: $0.id.rawValue)
            }
            .flatMap { argument -> [CommandLineToolInvocation.Component] in
                let components = argument.publicInvocationComponents
                let shouldRender = try context.registerHandledArgument(
                    command: command,
                    argumentName: argument.id.rawValue,
                    disposition: .defaultRender,
                    components: components
                )

                return shouldRender ? components : []
            }
    }
}

}

extension Never: CommandLineToolInvocationSummary.InvocationSummary {
    public typealias Command = AnyCommandLineTool

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        fatalError(.unavailable)
    }
}
