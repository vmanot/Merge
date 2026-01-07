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
    public static func buildBlock(_ components: [InvocationSummaryComponent<Command>]...) -> [InvocationSummaryComponent<Command>] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: InvocationSummaryComponent<Command>) -> [InvocationSummaryComponent<Command>] {
        [expression]
    }

    public static func buildExpression(_ expression: InvocationSummaryWhenCondition<Command>) -> [InvocationSummaryComponent<Command>] {
        [
            .conditional(
                { context in
                    expression.condition.evaluate(in: context)
                },
                ifTrue: expression.trueBranch,
                ifFalse: expression.falseBranch
            )
        ]
    }

    public static func buildExpression(_ expression: CommandLineToolInvocationSummary<Command>) -> [InvocationSummaryComponent<Command>] {
        expression._components
    }

    public static func buildExpression(_ expression: String) -> [InvocationSummaryComponent<Command>] {
        [.literal(expression)]
    }

    public static func buildExpression<Value>(_ expression: KeyPath<Command, InvocationSummaryValue<Value>>) -> [InvocationSummaryComponent<Command>] {
        [.value(expression)]
    }
    
    public static func buildExpression<Value>(_ expression: InvocationSummaryValue<Value>) -> [InvocationSummaryComponent<Command>] {
        [.value(expression)]
    }
    
    public static func buildExpression<Value>(_ expression: InvocationSummaryValueExpression<Command, Value>) -> [InvocationSummaryComponent<Command>] {
        [.value(expression)]
    }

    public static func buildOptional(_ component: [InvocationSummaryComponent<Command>]?) -> [InvocationSummaryComponent<Command>] {
        component ?? []
    }

    public static func buildEither(first component: [InvocationSummaryComponent<Command>]) -> [InvocationSummaryComponent<Command>] {
        component
    }

    public static func buildEither(second component: [InvocationSummaryComponent<Command>]) -> [InvocationSummaryComponent<Command>] {
        component
    }

    public static func buildArray(_ components: [[InvocationSummaryComponent<Command>]]) -> [InvocationSummaryComponent<Command>] {
        components.flatMap { $0 }
    }
}
