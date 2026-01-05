//
//  InvocationSummaryWhenCondition.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation

/*
 "swiftc"
 When($mode, is: .typeCheck) {
     When($emitModuleTrace, is: true) {
        "--emit-module-trace"
        "--emit-module-trace-path"
        $emitModuleTracePath
     }
 } /* else { } */
 */
public struct InvocationSummaryWhenCondition<Tool: AnyCommandLineTool>: InvocationSummary {
    internal let condition: (Tool) -> Bool
    internal let trueBranch: [InvocationSummaryComponent<Tool>]
    internal let falseBranch: [InvocationSummaryComponent<Tool>]?

    public init(
        _ condition: @escaping (Tool) -> Bool,
        @InvocationSummaryBuilder<Tool> _ content: () -> [InvocationSummaryComponent<Tool>]
    ) {
        self.condition = condition
        self.trueBranch = content()
        self.falseBranch = nil
    }

    public init(
        _ condition: @escaping (Tool) -> Bool,
        @InvocationSummaryBuilder<Tool> _ content: () -> [InvocationSummaryComponent<Tool>],
        @InvocationSummaryBuilder<Tool> `else` elseContent: () -> [InvocationSummaryComponent<Tool>]
    ) {
        self.condition = condition
        self.trueBranch = content()
        self.falseBranch = elseContent()
    }

    public func invocationArguments(for tool: AnyCommandLineTool) -> [String] {
        guard let typedTool = tool as? Tool else {
            assertionFailure("Invocation summary expected \(Tool.self) but received \(type(of: tool)).")
            return []
        }

        let branch = condition(typedTool) ? trueBranch : (falseBranch ?? [])
        return branch.flatMap { $0.resolve(in: typedTool) }
    }
}

extension InvocationSummaryWhenCondition {
    public init<Value: Equatable>(
        _ keyPath: KeyPath<Tool, InvocationSummaryValue<Value>>,
        is expected: Value,
        @InvocationSummaryBuilder<Tool> _ content: () -> [InvocationSummaryComponent<Tool>]
    ) {
        self.init({ tool in
            tool[keyPath: keyPath].value == expected
        }, content)
    }

    public init<Value: Equatable>(
        _ keyPath: KeyPath<Tool, InvocationSummaryValue<Value>>,
        is expected: Value,
        @InvocationSummaryBuilder<Tool> _ content: () -> [InvocationSummaryComponent<Tool>],
        @InvocationSummaryBuilder<Tool> `else` elseContent: () -> [InvocationSummaryComponent<Tool>]
    ) {
        self.init({ tool in
            tool[keyPath: keyPath].value == expected
        }, content, else: elseContent)
    }

    public init<Value: Equatable>(
        _ value: InvocationSummaryValue<Value>,
        is expected: Value,
        @InvocationSummaryBuilder<Tool> _ content: () -> [InvocationSummaryComponent<Tool>]
    ) {
        self.init({ _ in
            value.value == expected
        }, content)
    }

    public init<Value: Equatable>(
        _ value: InvocationSummaryValue<Value>,
        is expected: Value,
        @InvocationSummaryBuilder<Tool> _ content: () -> [InvocationSummaryComponent<Tool>],
        @InvocationSummaryBuilder<Tool> `else` elseContent: () -> [InvocationSummaryComponent<Tool>]
    ) {
        self.init({ _ in
            value.value == expected
        }, content, else: elseContent)
    }
}
