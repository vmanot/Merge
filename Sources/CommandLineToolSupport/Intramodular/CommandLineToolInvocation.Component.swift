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
    /// A grammar-aware component of a modeled command-line invocation.
    public struct Component: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
        public enum Storage: Hashable, Sendable {
            case executable(Argument)
            case selectedTool(Argument)
            case subcommand(Argument)
            case option(
                key: Argument?,
                separator: _CommandLineToolParameterKeyValueSeparator?,
                values: Arguments,
                multiValueEncoding: MultiValueParameterEncodingStrategy?,
                arguments: Arguments
            )
            case flag(Arguments)
            case positionalArgument(Arguments)
            case environmentAssignment(Arguments)
        }

        public enum Kind: CustomStringConvertible, CustomDebugStringConvertible, Hashable, Sendable {
            case executable
            case selectedTool
            case subcommand
            case option
            case flag
            case positionalArgument
            case environmentAssignment

            public var description: String {
                switch self {
                    case .executable:
                        "executable"
                    case .selectedTool:
                        "selectedTool"
                    case .subcommand:
                        "subcommand"
                    case .option:
                        "option"
                    case .flag:
                        "flag"
                    case .positionalArgument:
                        "positionalArgument"
                    case .environmentAssignment:
                        "environmentAssignment"
                }
            }

            public var debugDescription: String {
                "CommandLineToolInvocation.Component.Kind.\(description)"
            }
        }

        public var storage: Storage

        public var kind: Kind {
            storage.kind
        }

        public var arguments: Arguments {
            storage.arguments
        }

        public var key: Argument? {
            storage.key
        }

        public var separator: _CommandLineToolParameterKeyValueSeparator? {
            storage.separator
        }

        public var values: Arguments {
            storage.values
        }

        public var multiValueEncoding: MultiValueParameterEncodingStrategy? {
            storage.multiValueEncoding
        }

        public init(
            kind: Kind,
            arguments: Arguments
        ) {
            let storage: Storage

            switch kind {
                case .executable:
                    storage = .executable(arguments.elements.first ?? Argument(""))
                case .selectedTool:
                    storage = .selectedTool(arguments.elements.first ?? Argument(""))
                case .subcommand:
                    storage = .subcommand(arguments.elements.first ?? Argument(""))
                case .option:
                    storage = .option(
                        key: nil,
                        separator: nil,
                        values: arguments,
                        multiValueEncoding: nil,
                        arguments: arguments
                    )
                case .flag:
                    storage = .flag(arguments)
                case .positionalArgument:
                    storage = .positionalArgument(arguments)
                case .environmentAssignment:
                    storage = .environmentAssignment(arguments)
            }

            self.storage = storage
        }

        public init(
            kind: Kind,
            key: Argument?,
            separator: _CommandLineToolParameterKeyValueSeparator?,
            values: Arguments,
            multiValueEncoding: MultiValueParameterEncodingStrategy? = nil,
            arguments: Arguments
        ) {
            let storage: Storage

            switch kind {
                case .option:
                    storage = .option(
                        key: key,
                        separator: separator,
                        values: values,
                        multiValueEncoding: multiValueEncoding,
                        arguments: arguments
                    )
                default:
                    storage = Self(kind: kind, arguments: arguments).storage
            }

            self.storage = storage
        }

        public init(
            kind: Kind,
            argument: Argument
        ) {
            self.init(kind: kind, arguments: Arguments([argument]))
        }

        @_disfavoredOverload
        public init(
            kind: Kind,
            argument: String
        ) {
            self.init(kind: kind, argument: Argument(argument))
        }

        public static func executable(
            _ argument: Argument
        ) -> Self {
            Self(kind: .executable, argument: argument)
        }

        public static func selectedTool(
            _ argument: Argument
        ) -> Self {
            Self(kind: .selectedTool, argument: argument)
        }

        public static func subcommand(
            _ argument: Argument
        ) -> Self {
            Self(kind: .subcommand, argument: argument)
        }

        public static func option(
            key: Argument,
            value: Argument
        ) -> Self {
            Self.option(
                key: key,
                separator: .space,
                values: Arguments([value])
            )
        }

        public static func option(
            key: Argument,
            separator: _CommandLineToolParameterKeyValueSeparator,
            values: Arguments,
            multiValueEncoding: MultiValueParameterEncodingStrategy? = nil
        ) -> Self {
            return Self(
                kind: .option,
                key: key,
                separator: separator,
                values: values,
                multiValueEncoding: multiValueEncoding,
                arguments: _encodeOptionArguments(
                    key: key,
                    separator: separator,
                    values: values,
                    multiValueEncoding: multiValueEncoding
                )
            )
        }

        public static func option(
            key: Argument,
            separator: _CommandLineToolParameterKeyValueSeparator,
            values: [Argument],
            multiValueEncoding: MultiValueParameterEncodingStrategy? = nil
        ) -> Self {
            Self.option(
                key: key,
                separator: separator,
                values: Arguments(values),
                multiValueEncoding: multiValueEncoding
            )
        }

        public static func option(
            arguments: Arguments
        ) -> Self {
            Self(kind: .option, arguments: arguments)
        }

        public static func flag(
            _ argument: Argument
        ) -> Self {
            Self(kind: .flag, argument: argument)
        }

        public static func positionalArgument(
            _ argument: Argument
        ) -> Self {
            Self(kind: .positionalArgument, argument: argument)
        }

        public var argumentValues: [Argument] {
            arguments.elements
        }

        public var rawValues: [String] {
            arguments.rawValues
        }

        public var description: String {
            arguments.description
        }

        public var debugDescription: String {
            "CommandLineToolInvocation.Component(kind: \(kind.debugDescription), arguments: \(arguments.debugDescription))"
        }

        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "kind": kind,
                    "arguments": arguments,
                    "key": key as Any,
                    "separator": separator as Any,
                    "values": values,
                    "multiValueEncoding": multiValueEncoding as Any,
                    "rawValues": rawValues
                ],
                displayStyle: .struct
            )
        }
    }

    public var invocationComponents: [Component] {
        components
    }
}

extension CommandLineToolInvocation.Component {
    package static func _encodeOptionArguments(
        key: CommandLineToolInvocation.Argument,
        separator: _CommandLineToolParameterKeyValueSeparator,
        values: CommandLineToolInvocation.Arguments,
        multiValueEncoding: MultiValueParameterEncodingStrategy?
    ) -> CommandLineToolInvocation.Arguments {
        if multiValueEncoding == .spaceSeparated {
            return CommandLineToolInvocation.Arguments([key]) + values
        }

        if multiValueEncoding == .singleValue, separator == .space {
            return CommandLineToolInvocation.Arguments(values.elements.flatMap { [key, $0] })
        }

        if separator == .space, values.elements.count == 1 {
            return CommandLineToolInvocation.Arguments([key, values.elements[0]])
        }

        return CommandLineToolInvocation.Arguments(
            values.elements.map { value in
                CommandLineToolInvocation.Argument("\(key.rawValue)\(separator.rawValue)\(value.rawValue)")
            }
        )
    }
}

extension CommandLineToolInvocation.Component.Storage {
    public var kind: CommandLineToolInvocation.Component.Kind {
        switch self {
            case .executable:
                return .executable
            case .selectedTool:
                return .selectedTool
            case .subcommand:
                return .subcommand
            case .option:
                return .option
            case .flag:
                return .flag
            case .positionalArgument:
                return .positionalArgument
            case .environmentAssignment:
                return .environmentAssignment
        }
    }

    public var arguments: CommandLineToolInvocation.Arguments {
        switch self {
            case .executable(let argument), .selectedTool(let argument), .subcommand(let argument):
                return CommandLineToolInvocation.Arguments([argument])
            case .option(_, _, _, _, let arguments):
                return arguments
            case .flag(let arguments), .positionalArgument(let arguments), .environmentAssignment(let arguments):
                return arguments
        }
    }

    public var key: CommandLineToolInvocation.Argument? {
        if case .option(let key, _, _, _, _) = self {
            return key
        }

        return nil
    }

    public var separator: _CommandLineToolParameterKeyValueSeparator? {
        if case .option(_, let separator, _, _, _) = self {
            return separator
        }

        return nil
    }

    public var values: CommandLineToolInvocation.Arguments {
        switch self {
            case .option(_, _, let values, _, _):
                return values
            default:
                return arguments
        }
    }

    public var multiValueEncoding: MultiValueParameterEncodingStrategy? {
        if case .option(_, _, _, let multiValueEncoding, _) = self {
            return multiValueEncoding
        }

        return nil
    }
}
