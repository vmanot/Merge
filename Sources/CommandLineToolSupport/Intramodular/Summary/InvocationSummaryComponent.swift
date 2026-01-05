import Foundation
import Swallow

public struct InvocationSummaryComponent<Tool: AnyCommandLineTool> {
    fileprivate let resolve: (Tool) -> [String]

    private init(resolve: @escaping (Tool) -> [String]) {
        self.resolve = resolve
    }
    
    public func resolve(in tool: Tool) -> [String] {
        resolve(tool)
    }
}

extension InvocationSummaryComponent {
    static func literal(_ literal: String) -> Self {
        .init(resolve: { _ in
            literal.split(whereSeparator: \.isWhitespace).map(String.init)
        })
    }

    static func value<Value>(_ keyPath: KeyPath<Tool, InvocationSummaryValue<Value>>) -> Self {
        .init(resolve: { tool in
            tool[keyPath: keyPath].argumentTokens()
        })
    }

    static func value<Value>(_ value: InvocationSummaryValue<Value>) -> Self {
        .init(resolve: { _ in
            value.argumentTokens()
        })
    }

    static func conditional(
        _ condition: @escaping (Tool) -> Bool,
        ifTrue trueBranch: [InvocationSummaryComponent<Tool>],
        ifFalse falseBranch: [InvocationSummaryComponent<Tool>]?
    ) -> Self {
        .init(resolve: { tool in
            let branch = condition(tool) ? trueBranch : (falseBranch ?? [])
            return branch.flatMap { $0.resolve(tool) }
        })
    }
}
