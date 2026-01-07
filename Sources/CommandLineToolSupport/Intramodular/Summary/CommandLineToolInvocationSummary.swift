//
//  CommandLineToolInvocationSummary.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

public protocol InvocationSummary {
    associatedtype Command: AnyCommandLineTool
    typealias Context = InvocationSummaryContext<Command>
    
    func makeInvocationArguments(context: Context) throws -> [String]
}

// MARK: - Supplementary

public struct CommandLineToolInvocationSummary<Command: AnyCommandLineTool>: InvocationSummary {
    let _components: [InvocationSummaryComponent<Command>]

    public init(
        @InvocationSummaryBuilder<Command> _ content: () -> [InvocationSummaryComponent<Command>]
    ) {
        self._components = content()
    }

    public func makeInvocationArguments(
        context: InvocationSummaryContext<Command>
    ) throws -> [String] {
        _components
            .flatMap { $0.resolve(in: context) }
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
        fileprivate var components: [InvocationSummaryComponent<Command>] = []

        public init(literalCapacity: Int, interpolationCount: Int) {
            components.reserveCapacity(literalCapacity + interpolationCount)
        }

        public mutating func appendLiteral(_ literal: String) {
            components.append(.literal(literal))
        }

        public mutating func appendInterpolation(_ literal: String) {
            components.append(.literal(literal))
        }

        public mutating func appendInterpolation<Value>(_ keyPath: KeyPath<Command, InvocationSummaryValue<Value>>) {
            components.append(.value(keyPath))
        }

        public mutating func appendInterpolation<Value>(_ value: InvocationSummaryValue<Value>) {
            components.append(.value(value))
        }
    }
}
