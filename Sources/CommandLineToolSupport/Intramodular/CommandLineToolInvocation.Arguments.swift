//
// Copyright (c) Vatsal Manot
//


import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolInvocation {
    /// Additional argv values that can be composed onto a modeled command-line tool invocation.
    public struct Arguments: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, ExpressibleByArrayLiteral, Hashable, Sendable {
        public typealias ArrayLiteralElement = Argument

        public var elements: [Argument]

        public init(elements: [Argument]) {
            self.elements = elements
        }

        public init() {
            self.init(elements: [])
        }

        public init(_ elements: [Argument]) {
            self.init(elements: elements)
        }

        public init(_ elements: [String]) {
            self.init(
                elements: elements.map { (element: String) -> Argument in
                    Argument(element)
                }
            )
        }

        public init(_ elements: String...) {
            self.init(elements)
        }

        public init(arrayLiteral elements: Argument...) {
            self.init(elements)
        }

        public var rawValues: [String] {
            elements.map(\.rawValue)
        }

        public var isEmpty: Bool {
            elements.isEmpty
        }

        public mutating func append(
            _ argument: Argument
        ) {
            elements.append(argument)
        }

        public mutating func append(
            contentsOf arguments: Arguments
        ) {
            elements.append(contentsOf: arguments.elements)
        }

        @_disfavoredOverload
        public mutating func append(
            contentsOf arguments: [String]
        ) {
            append(contentsOf: Arguments(arguments))
        }

        public static func + (
            lhs: Self,
            rhs: Self
        ) -> Self {
            Self(elements: lhs.elements + rhs.elements)
        }

        @_disfavoredOverload
        public static func + (
            lhs: Self,
            rhs: [String]
        ) -> Self {
            lhs + Self(rhs)
        }

        public var description: String {
            rawValues.joined(separator: " ")
        }

        public var debugDescription: String {
            "CommandLineToolInvocation.Arguments(\(String(reflecting: rawValues)))"
        }

        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "elements": elements,
                    "rawValues": rawValues
                ],
                displayStyle: .struct
            )
        }
    }

    /// Structural command-line invocation components that can be composed before flattening to argv.
    public struct Components: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, ExpressibleByArrayLiteral, Hashable, Sendable {
        public typealias ArrayLiteralElement = Component

        public var elements: [Component]

        public init(elements: [Component]) {
            self.elements = elements
        }

        public init() {
            self.init(elements: [])
        }

        public init(_ elements: [Component]) {
            self.init(elements: elements)
        }

        public init(argumentValues: [Argument]) {
            self.init(elements: CommandLineToolInvocation._components(from: argumentValues))
        }

        public init(arguments: Arguments) {
            self.init(argumentValues: arguments.elements)
        }

        public init(arrayLiteral elements: Component...) {
            self.init(elements)
        }

        public var argumentValues: [Argument] {
            elements.flatMap(\.argumentValues)
        }

        public var arguments: Arguments {
            Arguments(argumentValues)
        }

        public var rawValues: [String] {
            argumentValues.map(\.rawValue)
        }

        public var isEmpty: Bool {
            elements.isEmpty
        }

        public mutating func append(
            _ component: Component
        ) {
            elements.append(component)
        }

        public mutating func append(
            contentsOf components: Components
        ) {
            elements.append(contentsOf: components.elements)
        }

        public mutating func append(
            contentsOf components: [Component]
        ) {
            elements.append(contentsOf: components)
        }

        public static func + (
            lhs: Self,
            rhs: Self
        ) -> Self {
            Self(elements: lhs.elements + rhs.elements)
        }

        public var description: String {
            arguments.description
        }

        public var debugDescription: String {
            "CommandLineToolInvocation.Components(\(String(reflecting: elements)))"
        }

        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "elements": elements,
                    "argumentValues": argumentValues,
                    "rawValues": rawValues
                ],
                displayStyle: .struct
            )
        }
    }

    public func appending(
        _ arguments: Arguments
    ) -> Self {
        Self(argumentValues: argumentValues + arguments.elements)
    }

    public func appending(
        _ components: Components
    ) -> Self {
        Self(components: self.components + components.elements)
    }
}
