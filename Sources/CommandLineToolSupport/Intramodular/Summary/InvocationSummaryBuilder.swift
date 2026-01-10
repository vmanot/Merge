//
//  InvocationSummaryBuilder.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

@resultBuilder
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
    public static func buildFinalResult<Content>(
        _ component: Content
    ) -> TupleInvocationSummary<Command, (Content, DefaultInvocationSummary<Command>)> where Content: InvocationSummary {
        TupleInvocationSummary(
            (component, DefaultInvocationSummary<Command>())
        )
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

// MARK: - Supplementary

public struct _InvocationSummaryLiteral<Command: AnyCommandLineTool>: InvocationSummary {
    let text: String
    
    public init(text: String) {
        self.text = text
    }
    
    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [String] {
        [text]
    }
}

public struct _EmptyInvocationSummary<Command: AnyCommandLineTool>: InvocationSummary {
    @inlinable public init() { }
    
    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [String] {
        []
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
    ) throws -> [String] {
        guard let content else {
            return []
        }
        
        return try content.makeInvocationArguments(
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
    ) throws -> [String] {
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
}

extension Never: InvocationSummary {
    public func makeInvocationArguments(command: AnyCommandLineTool, parent: AnyCommandLineTool?, context: Context) throws -> [String] {
        fatalError(.unavailable)
    }
    
    public typealias Command = AnyCommandLineTool
}
