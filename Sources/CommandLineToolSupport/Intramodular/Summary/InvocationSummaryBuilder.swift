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
    public typealias Component = [any InvocationSummary<Command>]
    
    public static func buildBlock() -> Component {
        []
    }
    
    public static func buildBlock(_ components: Component...) -> Component {
        components.flatMap { $0 }
    }
    
    public static func buildExpression(
        _ expression: Component
    ) -> Component {
        expression
    }
    
    public static func buildExpression(
        _ expression: String
    ) -> Component {
        [_InvocationSummaryLiteral(text: expression)]
    }
    
    public static func buildExpression<Parent: AnyCommandLineTool, Value: InvocationSummaryValue>(
        _ expression: InvocationSummaryValueReferenceFromParent<Parent, Command, Value>
    ) -> Component where Command : _Subcommand, Command.ParentCommand == Parent {
        [InvocationSummaryValueReferenceFromParent(keyPath: expression.keyPath)]
    }
    
    public static func buildExpression<Value>(
        _ expression: KeyPath<Command, _CommandLineToolFlag<Value>>
    ) -> Component {
        [InvocationSummaryValueReference(keyPath: expression)]
    }
    
    public static func buildExpression<Value>(
        _ expression: KeyPath<Command, _CommandLineToolParameter<Value>>
    ) -> Component {
        [InvocationSummaryValueReference(keyPath: expression)]
    }
    
    @_disfavoredOverload
    public static func buildExpression<S: InvocationSummary>(
        _ expression: S
    ) -> Component where S.Command == Command {
        [expression]
    }
    
    public static func buildOptional(
        _ component: Component?
    ) -> Component {
        component ?? []
    }
    
    public static func buildEither(
        first component: Component
    ) -> Component {
        component
    }
    
    public static func buildEither(
        second component: Component
    ) -> Component {
        component
    }
    
    public static func buildArray(
        _ components: [Component]
    ) -> Component {
        components.flatMap { $0 }
    }
    
    public static func buildLimitedAvailability(
        _ component: Component
    ) -> Component {
        component
    }
}

private struct _InvocationSummaryLiteral<Command: AnyCommandLineTool>: InvocationSummary {
    let text: String
    
    func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [String] {
        [text]
    }
}
