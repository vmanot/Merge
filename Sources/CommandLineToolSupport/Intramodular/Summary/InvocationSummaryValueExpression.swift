//
//  InvocationSummaryValueExpression.swift
//  Merge
//

import Foundation

public struct InvocationSummaryValueExpression<Command: AnyCommandLineTool, Value> {
    fileprivate let resolve: (InvocationSummaryContext<Command>) -> InvocationSummaryValue<Value>?

    fileprivate init(resolve: @escaping (InvocationSummaryContext<Command>) -> InvocationSummaryValue<Value>?) {
        self.resolve = resolve
    }

    public static func value(_ value: InvocationSummaryValue<Value>) -> Self {
        .init(resolve: { _ in value })
    }

    public static func keyPath(_ keyPath: KeyPath<Command, InvocationSummaryValue<Value>>) -> Self {
        .init(resolve: { context in
            context.command[keyPath: keyPath]
        })
    }

    public static func parent<Parent: AnyCommandLineTool>(
        _ keyPath: KeyPath<Parent, InvocationSummaryValue<Value>>
    ) -> Self {
        .init(resolve: { context in
            guard let parent = context.parent(of: Parent.self) else {
                assertionFailure("Invocation summary expected parent \(Parent.self) but none was found.")
                return nil
            }

            return parent[keyPath: keyPath]
        })
    }

    public func resolveValue(in context: InvocationSummaryContext<Command>) -> Value? {
        resolve(context)?.value
    }

    public func argumentTokens(in context: InvocationSummaryContext<Command>) -> [String] {
        resolve(context)?.argumentTokens() ?? []
    }
}
