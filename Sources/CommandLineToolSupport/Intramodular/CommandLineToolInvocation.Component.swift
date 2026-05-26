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
            case environmentAssignment(
                key: Argument?,
                value: Argument?,
                arguments: Arguments
            )
            case buildSettingAssignment(
                key: Argument?,
                value: Argument?,
                arguments: Arguments
            )
            case unmodeled(Unmodeled)
        }

        public enum Kind: CustomStringConvertible, CustomDebugStringConvertible, Hashable, Sendable {
            case executable
            case selectedTool
            case subcommand
            case option
            case flag
            case positionalArgument
            case environmentAssignment
            case buildSettingAssignment
            case unmodeled

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
                    case .buildSettingAssignment:
                        "buildSettingAssignment"
                    case .unmodeled:
                        "unmodeled"
                }
            }

            public var debugDescription: String {
                "CommandLineToolInvocation.Component.Kind.\(description)"
            }
        }

        public var storage: Storage

        public init(
            storage: Storage
        ) {
            self.storage = storage
        }

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

        public var unmodeled: Unmodeled? {
            storage.unmodeled
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
                    storage = .environmentAssignment(
                        key: nil,
                        value: nil,
                        arguments: arguments
                    )
                case .buildSettingAssignment:
                    storage = .buildSettingAssignment(
                        key: nil,
                        value: nil,
                        arguments: arguments
                    )
                case .unmodeled:
                    storage = .unmodeled(
                        Unmodeled(arguments: arguments)
                    )
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

        public static func environmentAssignment(
            key: Argument,
            value: Argument
        ) -> Self {
            Self(
                storage: .environmentAssignment(
                    key: key,
                    value: value,
                    arguments: Arguments([Argument("\(key.rawValue)=\(value.rawValue)")])
                )
            )
        }

        public static func environmentAssignment(
            arguments: Arguments
        ) -> Self {
            Self(kind: .environmentAssignment, arguments: arguments)
        }

        public static func buildSettingAssignment(
            key: Argument,
            value: Argument
        ) -> Self {
            Self(
                storage: .buildSettingAssignment(
                    key: key,
                    value: value,
                    arguments: Arguments([Argument("\(key.rawValue)=\(value.rawValue)")])
                )
            )
        }

        public static func buildSettingAssignment(
            arguments: Arguments
        ) -> Self {
            Self(kind: .buildSettingAssignment, arguments: arguments)
        }

        public static func unmodeled(
            _ unmodeled: Unmodeled
        ) -> Self {
            Self(storage: .unmodeled(unmodeled))
        }

        public static func unmodeled(
            arguments: Arguments,
            source: Unmodeled.Source = .unknown,
            semantics: Set<Unmodeled.Semantics> = []
        ) -> Self {
            .unmodeled(
                Unmodeled(
                    arguments: arguments,
                    source: source,
                    semantics: semantics
                )
            )
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
                    "unmodeled": unmodeled as Any,
                    "rawValues": rawValues
                ],
                displayStyle: .struct
            )
        }

        public struct Unmodeled: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
            public enum Source: CustomStringConvertible, CustomDebugStringConvertible, Hashable, Sendable {
                case unknown
                case userProvided(String)
                case legacyAPI(String)

                public var description: String {
                    switch self {
                        case .unknown:
                            "unknown"
                        case .userProvided(let value):
                            "userProvided(\(value))"
                        case .legacyAPI(let value):
                            "legacyAPI(\(value))"
                    }
                }

                public var debugDescription: String {
                    "CommandLineToolInvocation.Component.Unmodeled.Source.\(description)"
                }
            }

            public enum Semantics: CustomStringConvertible, CustomDebugStringConvertible, Hashable, Sendable {
                case mayContainMultipleArguments
                case shellFragment
                case toolSpecific(String)

                public var description: String {
                    switch self {
                        case .mayContainMultipleArguments:
                            "mayContainMultipleArguments"
                        case .shellFragment:
                            "shellFragment"
                        case .toolSpecific(let value):
                            "toolSpecific(\(value))"
                    }
                }

                public var debugDescription: String {
                    "CommandLineToolInvocation.Component.Unmodeled.Semantics.\(description)"
                }
            }

            public var arguments: Arguments
            public var source: Source
            public var semantics: Set<Semantics>

            public init(
                arguments: Arguments,
                source: Source = .unknown,
                semantics: Set<Semantics> = []
            ) {
                self.arguments = arguments
                self.source = source
                self.semantics = semantics
            }

            public var description: String {
                arguments.description
            }

            public var debugDescription: String {
                "CommandLineToolInvocation.Component.Unmodeled(arguments: \(arguments.debugDescription), source: \(source.debugDescription), semantics: \(semantics))"
            }

            public var customMirror: Mirror {
                Mirror(
                    self,
                    children: [
                        "arguments": arguments,
                        "source": source,
                        "semantics": semantics
                    ],
                    displayStyle: .struct
                )
            }
        }
    }

    public var invocationComponents: [Component] {
        components
    }
}

extension CommandLineToolInvocation.Component {
    public func isOption(
        named name: String
    ) -> Bool {
        kind == .option && key?.rawValue == name
    }

    public func replacingOptionValues(
        _ values: CommandLineToolInvocation.Arguments
    ) throws -> Self {
        guard kind == .option, let key, let separator else {
            return self
        }

        return .option(
            key: key,
            separator: separator,
            values: values,
            multiValueEncoding: multiValueEncoding
        )
    }

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

    package static func _component(
        fromRawArgument argument: CommandLineToolInvocation.Argument,
        isExecutablePosition: Bool,
        allowsEnvironmentAssignment: Bool = false
    ) -> Self {
        if allowsEnvironmentAssignment, let assignment = _environmentAssignmentBoundary(in: argument) {
            return .environmentAssignment(
                key: assignment.key,
                value: assignment.value
            )
        }

        guard !isExecutablePosition else {
            return .executable(argument)
        }

        if let option = _joinedOptionBoundary(in: argument) {
            return .option(
                key: option.key,
                separator: option.separator,
                values: [option.value]
            )
        }

        return .positionalArgument(argument)
    }

    private static func _environmentAssignmentBoundary(
        in argument: CommandLineToolInvocation.Argument
    ) -> (key: CommandLineToolInvocation.Argument, value: CommandLineToolInvocation.Argument)? {
        guard
            case .string(let rawValue) = argument.storage,
            let separatorIndex = rawValue.firstIndex(of: "=")
        else {
            return nil
        }

        let key = String(rawValue[..<separatorIndex])

        guard _isEnvironmentAssignmentName(key) else {
            return nil
        }

        let value = String(rawValue[rawValue.index(after: separatorIndex)...])

        return (
            CommandLineToolInvocation.Argument(key),
            CommandLineToolInvocation.Argument(value)
        )
    }

    private static func _joinedOptionBoundary(
        in argument: CommandLineToolInvocation.Argument
    ) -> (key: CommandLineToolInvocation.Argument, separator: _CommandLineToolParameterKeyValueSeparator, value: CommandLineToolInvocation.Argument)? {
        guard case .string(let rawValue) = argument.storage, rawValue.hasPrefix("-") else {
            return nil
        }

        let separators: [_CommandLineToolParameterKeyValueSeparator] = [.equal, .colon, .plus]

        guard let match = separators
            .compactMap({ separator -> (index: String.Index, separator: _CommandLineToolParameterKeyValueSeparator)? in
                guard let index = rawValue.firstIndex(of: Character(separator.rawValue)) else {
                    return nil
                }

                return (index, separator)
            })
            .sorted(by: { $0.index < $1.index })
            .first
        else {
            return nil
        }

        let key = String(rawValue[..<match.index])
        let value = String(rawValue[rawValue.index(after: match.index)...])

        guard !key.isEmpty, !value.isEmpty else {
            return nil
        }

        return (
            CommandLineToolInvocation.Argument(key),
            match.separator,
            CommandLineToolInvocation.Argument(value)
        )
    }

    private static func _isEnvironmentAssignmentName(
        _ value: String
    ) -> Bool {
        guard let first = value.unicodeScalars.first else {
            return false
        }

        guard first == "_" || CharacterSet.letters.contains(first) else {
            return false
        }

        return value.unicodeScalars.dropFirst().allSatisfy {
            $0 == "_" || CharacterSet.alphanumerics.contains($0)
        }
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
            case .buildSettingAssignment:
                return .buildSettingAssignment
            case .unmodeled:
                return .unmodeled
        }
    }

    public var arguments: CommandLineToolInvocation.Arguments {
        switch self {
            case .executable(let argument), .selectedTool(let argument), .subcommand(let argument):
                return CommandLineToolInvocation.Arguments([argument])
            case .option(_, _, _, _, let arguments):
                return arguments
            case .flag(let arguments), .positionalArgument(let arguments), .environmentAssignment(_, _, let arguments), .buildSettingAssignment(_, _, let arguments):
                return arguments
            case .unmodeled(let unmodeled):
                return unmodeled.arguments
        }
    }

    public var key: CommandLineToolInvocation.Argument? {
        switch self {
            case .option(let key, _, _, _, _):
                return key
            case .environmentAssignment(let key, _, _):
                return key
            case .buildSettingAssignment(let key, _, _):
                return key
            default:
                return nil
        }
    }

    public var separator: _CommandLineToolParameterKeyValueSeparator? {
        switch self {
            case .option(_, let separator, _, _, _):
                return separator
            case .environmentAssignment:
                return .equal
            case .buildSettingAssignment:
                return .equal
            default:
                return nil
        }
    }

    public var values: CommandLineToolInvocation.Arguments {
        switch self {
            case .option(_, _, let values, _, _):
                return values
            case .environmentAssignment(_, let value, _):
                return CommandLineToolInvocation.Arguments(value.map { [$0] } ?? [])
            case .buildSettingAssignment(_, let value, _):
                return CommandLineToolInvocation.Arguments(value.map { [$0] } ?? [])
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

    public var unmodeled: CommandLineToolInvocation.Component.Unmodeled? {
        if case .unmodeled(let unmodeled) = self {
            return unmodeled
        }

        return nil
    }
}
