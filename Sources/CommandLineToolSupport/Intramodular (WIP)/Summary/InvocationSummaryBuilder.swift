//
//  InvocationSummaryBuilder.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

extension CommandLineToolInvocationSummary {
@resultBuilder
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
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

}
