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
        _ expression: InvocationSummaryValueFromParentCommandReference<Parent, Command, Value>
    ) -> Component where Command : _Subcommand, Command.ParentCommand == Parent {
        [InvocationSummaryValueFromParentCommandReference(keyPath: expression.keyPath)]
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
        context: InvocationSummaryContext<Command>
    ) throws -> [String] {
        [text]
    }
}
