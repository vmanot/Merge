import Foundation
import Swallow

public struct InvocationSummaryComponent<Command: AnyCommandLineTool> {
    fileprivate let resolve: (InvocationSummaryContext<Command>) -> [String]

    private init(resolve: @escaping (InvocationSummaryContext<Command>) -> [String]) {
        self.resolve = resolve
    }
    
    public func resolve(in command: Command, parent: AnyCommandLineTool? = nil) -> [String] {
        resolve(.init(command: command, parent: parent))
    }
    
    func resolve(in context: InvocationSummaryContext<Command>) -> [String] {
        resolve(context)
    }
}

extension InvocationSummaryComponent {
    static func literal(_ literal: String) -> Self {
        .init(resolve: { _ in
            literal.split(whereSeparator: \.isWhitespace).map(String.init)
        })
    }

    static func value<Value>(_ keyPath: KeyPath<Command, InvocationSummaryValue<Value>>) -> Self {
        .init(resolve: { context in
            context.command[keyPath: keyPath].argumentTokens()
        })
    }

    static func value<Value>(_ value: InvocationSummaryValue<Value>) -> Self {
        .init(resolve: { _ in
            value.argumentTokens()
        })
    }
    
    static func value<Value>(_ value: InvocationSummaryValueExpression<Command, Value>) -> Self {
        .init(resolve: { context in
            value.argumentTokens(in: context)
        })
    }

    static func conditional(
        _ condition: @escaping (InvocationSummaryContext<Command>) -> Bool,
        ifTrue trueBranch: [InvocationSummaryComponent<Command>],
        ifFalse falseBranch: [InvocationSummaryComponent<Command>]?
    ) -> Self {
        .init(resolve: { context in
            let branch = condition(context) ? trueBranch : (falseBranch ?? [])
            return branch.flatMap { $0.resolve(in: context) }
        })
    }
}
