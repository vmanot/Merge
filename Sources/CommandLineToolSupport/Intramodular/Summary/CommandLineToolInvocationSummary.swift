//
//  CommandLineToolInvocationSummary.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

public struct CommandLineToolInvocationSummary<Tool: AnyCommandLineTool>: InvocationSummary {
    let _components: [InvocationSummaryComponent<Tool>]

    public init(
        @InvocationSummaryBuilder<Tool> _ content: () -> [InvocationSummaryComponent<Tool>]
    ) {
        self._components = content()
    }

    public func invocationArguments(for command: Tool) -> [String] {
        return _components
            .flatMap { $0.resolve(in: command) }
            .filter { !$0.isEmpty }
    }
}

extension CommandLineToolInvocationSummary: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self._components = [.literal(value)]
    }

    public init(stringInterpolation: StringInterpolation) {
        self._components = stringInterpolation.components
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var components: [InvocationSummaryComponent<Tool>] = []

        public init(literalCapacity: Int, interpolationCount: Int) {
            components.reserveCapacity(literalCapacity + interpolationCount)
        }

        public mutating func appendLiteral(_ literal: String) {
            components.append(.literal(literal))
        }

        public mutating func appendInterpolation(_ literal: String) {
            components.append(.literal(literal))
        }

        public mutating func appendInterpolation<Value>(_ keyPath: KeyPath<Tool, InvocationSummaryValue<Value>>) {
            components.append(.value(keyPath))
        }

        public mutating func appendInterpolation<Value>(_ value: InvocationSummaryValue<Value>) {
            components.append(.value(value))
        }
    }
}
