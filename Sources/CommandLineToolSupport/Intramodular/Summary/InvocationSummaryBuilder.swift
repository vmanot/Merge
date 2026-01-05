//
//  InvocationSummaryBuilder.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

@resultBuilder
public struct InvocationSummaryBuilder<Tool: AnyCommandLineTool> {
    public static func buildBlock(_ components: [InvocationSummaryComponent<Tool>]...) -> [InvocationSummaryComponent<Tool>] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: InvocationSummaryComponent<Tool>) -> [InvocationSummaryComponent<Tool>] {
        [expression]
    }

    public static func buildExpression(_ expression: InvocationSummaryWhenCondition<Tool>) -> [InvocationSummaryComponent<Tool>] {
        [
            .conditional(
                expression.condition,
                ifTrue: expression.trueBranch,
                ifFalse: expression.falseBranch
            )
        ]
    }

    public static func buildExpression(_ expression: CommandLineToolInvocationSummary<Tool>) -> [InvocationSummaryComponent<Tool>] {
        expression._components
    }

    public static func buildExpression(_ expression: String) -> [InvocationSummaryComponent<Tool>] {
        [.literal(expression)]
    }

    public static func buildExpression<Value>(_ expression: KeyPath<Tool, InvocationSummaryValue<Value>>) -> [InvocationSummaryComponent<Tool>] {
        [.value(expression)]
    }
    
    public static func buildExpression<Value>(_ expression: InvocationSummaryValue<Value>) -> [InvocationSummaryComponent<Tool>] {
        [.value(expression)]
    }

    public static func buildOptional(_ component: [InvocationSummaryComponent<Tool>]?) -> [InvocationSummaryComponent<Tool>] {
        component ?? []
    }

    public static func buildEither(first component: [InvocationSummaryComponent<Tool>]) -> [InvocationSummaryComponent<Tool>] {
        component
    }

    public static func buildEither(second component: [InvocationSummaryComponent<Tool>]) -> [InvocationSummaryComponent<Tool>] {
        component
    }

    public static func buildArray(_ components: [[InvocationSummaryComponent<Tool>]]) -> [InvocationSummaryComponent<Tool>] {
        components.flatMap { $0 }
    }
}
