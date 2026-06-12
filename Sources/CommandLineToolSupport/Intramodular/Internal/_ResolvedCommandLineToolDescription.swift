//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow
import Collections

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension CommandLineToolInvocation.Argument {
    init?(
        _resolvedInvocationScalar value: Any
    ) {
        if let url = value as? URL {
            self.init(fileURL: url)
        } else if let value = value as? any CLT.ArgumentValueConvertible {
            self.init(_argumentValueConvertible: value)
        } else {
            return nil
        }
    }
    
    init(
        _argumentValueConvertible value: any CLT.ArgumentValueConvertible
    ) {
        if let url = value as? URL {
            self.init(fileURL: url)
        } else {
            self.init(value.argumentValue)
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private enum _ResolvedInvocationValueLowering {
    static func scalarArgument(
        from value: Any
    ) -> CommandLineToolInvocation.Argument? {
        let value = _unwrapOptional(value)
        
        guard let value else {
            return nil
        }
        
        return CommandLineToolInvocation.Argument(_resolvedInvocationScalar: value)
    }
    
    static func arguments(
        from value: Any
    ) -> CommandLineToolInvocation.Arguments {
        let value = _unwrapOptional(value)
        
        guard let value else {
            return []
        }
        
        if let scalar = CommandLineToolInvocation.Argument(_resolvedInvocationScalar: value) {
            return scalar.rawValue.isEmpty ? [] : [scalar]
        }
        
        let mirror = Mirror(reflecting: value)
        
        guard mirror.displayStyle == .collection else {
            return []
        }
        
        return CommandLineToolInvocation.Arguments(
            mirror.children.flatMap { child in
                arguments(from: child.value).elements
            }
        )
    }
    
    private static func _unwrapOptional(
        _ value: Any
    ) -> Any? {
        let mirror = Mirror(reflecting: value)
        
        guard mirror.displayStyle == .optional else {
            return value
        }
        
        return mirror.children.first?.value
    }
}

/// The most granular and "resolved" representation of a command-line tool within some context.
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct _ResolvedCommandLineToolDescription: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, MergeOperatable {
    public struct ArgumentID: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
        /// The reflected Swift property name for the argument wrapper.
        public let rawValue: String
        public let commandName: CommandLineTool.Name
        
        public init(
            rawValue: String,
            commandName: CommandLineTool.Name
        ) {
            self.rawValue = rawValue
            self.commandName = commandName
        }
        
        public init(
            rawValue: String,
            commandName: String
        ) {
            self.init(
                rawValue: rawValue,
                commandName: CommandLineTool.Name(commandName)
            )
        }
        
        public var propertyName: String {
            rawValue
        }
        
        public var description: String {
            "\(commandName.rawValue).\(rawValue)"
        }
        
        public var debugDescription: String {
            "ArgumentID(rawValue: \(String(reflecting: rawValue)), commandName: \(String(reflecting: commandName)))"
        }
        
        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "rawValue": rawValue,
                    "propertyName": propertyName,
                    "commandName": commandName
                ],
                displayStyle: .struct
            )
        }
    }
    
    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct InvocationComponent: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
        public enum Kind: Hashable, Sendable {
            case positionalArgument
            case option
            case flag
        }
        
        public var kind: Kind
        public var key: CommandLineToolInvocation.Argument?
        public var separator: _CommandLineToolParameterKeyValueSeparator?
        public var values: CommandLineToolInvocation.Arguments
        public var multiValueEncoding: MultiValueParameterEncodingStrategy?
        
        public init(
            kind: Kind,
            key: CommandLineToolInvocation.Argument? = nil,
            separator: _CommandLineToolParameterKeyValueSeparator? = nil,
            values: CommandLineToolInvocation.Arguments,
            multiValueEncoding: MultiValueParameterEncodingStrategy? = nil
        ) {
            self.kind = kind
            self.key = key
            self.separator = separator
            self.values = values
            self.multiValueEncoding = multiValueEncoding
        }
        
        public static func positionalArgument(
            _ value: CommandLineToolInvocation.Argument
        ) -> Self {
            Self(kind: .positionalArgument, values: CommandLineToolInvocation.Arguments([value]))
        }
        
        public static func option(
            key: CommandLineToolInvocation.Argument,
            separator: _CommandLineToolParameterKeyValueSeparator,
            values: [CommandLineToolInvocation.Argument],
            multiValueEncoding: MultiValueParameterEncodingStrategy? = nil
        ) -> Self {
            Self(
                kind: .option,
                key: key,
                separator: separator,
                values: CommandLineToolInvocation.Arguments(values),
                multiValueEncoding: multiValueEncoding
            )
        }
        
        public static func option(
            key: CommandLineToolInvocation.Argument,
            separator: _CommandLineToolParameterKeyValueSeparator,
            values: CommandLineToolInvocation.Arguments,
            multiValueEncoding: MultiValueParameterEncodingStrategy? = nil
        ) -> Self {
            Self(
                kind: .option,
                key: key,
                separator: separator,
                values: values,
                multiValueEncoding: multiValueEncoding
            )
        }
        
        public static func flag(
            _ value: CommandLineToolInvocation.Argument
        ) -> Self {
            Self(kind: .flag, values: CommandLineToolInvocation.Arguments([value]))
        }
        
        public var invocationArgumentValues: [CommandLineToolInvocation.Argument] {
            switch kind {
                case .positionalArgument, .flag:
                    return values.elements
                case .option:
                    guard let key, let separator, !values.isEmpty else {
                        return []
                    }
                    
                    return CommandLineToolInvocation.Component._encodeOptionArguments(
                        key: key,
                        separator: separator,
                        values: values,
                        multiValueEncoding: multiValueEncoding
                    ).elements
            }
        }
        
        public var publicInvocationComponent: CommandLineToolInvocation.Component {
            switch kind {
                case .positionalArgument:
                    return CommandLineToolInvocation.Component(
                        kind: .positionalArgument,
                        arguments: values
                    )
                case .flag:
                    return CommandLineToolInvocation.Component(
                        kind: .flag,
                        arguments: values
                    )
                case .option:
                    guard let key, let separator else {
                        return .option(arguments: CommandLineToolInvocation.Arguments(invocationArgumentValues))
                    }
                    
                    return .option(
                        key: key,
                        separator: separator,
                        values: values,
                        multiValueEncoding: multiValueEncoding
                    )
            }
        }
        
        public var description: String {
            invocationArgumentValues.map(\.rawValue).joined(separator: " ")
        }
        
        public var debugDescription: String {
            "InvocationComponent(kind: \(kind), key: \(String(describing: key)), separator: \(String(describing: separator)), values: \(values), multiValueEncoding: \(String(describing: multiValueEncoding)))"
        }
        
        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "kind": kind,
                    "key": key as Any,
                    "separator": separator as Any,
                    "values": values,
                    "multiValueEncoding": multiValueEncoding as Any,
                    "invocationArgumentValues": invocationArgumentValues
                ],
                displayStyle: .struct
            )
        }
    }
    
    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct IdentifiedInvocationComponent: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
        public var argumentID: ArgumentID
        public var defaultPosition: _CommandLineToolArgumentPosition?
        public var component: CommandLineToolInvocation.Component
        
        public init(
            argumentID: ArgumentID,
            defaultPosition: _CommandLineToolArgumentPosition?,
            component: CommandLineToolInvocation.Component
        ) {
            self.argumentID = argumentID
            self.defaultPosition = defaultPosition
            self.component = component
        }
        
        public var description: String {
            "\(argumentID): \(component)"
        }
        
        public var debugDescription: String {
            "IdentifiedInvocationComponent(argumentID: \(argumentID.debugDescription), defaultPosition: \(String(describing: defaultPosition)), component: \(component.debugDescription))"
        }
        
        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "argumentID": argumentID,
                    "defaultPosition": defaultPosition as Any,
                    "component": component
                ],
                displayStyle: .struct
            )
        }
    }
    
    public typealias ResolvedArguments = IdentifierIndexingArrayOf<_AnyResolvedCommandLineToolInvocationArgument>
    public typealias ResolvedSubcommands = IdentifierIndexingArrayOf<Subcommand>
    
    /// A resolved argument.
    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Argument: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, _ResolvedCommandLineToolInvocationArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let defaultPosition: _CommandLineToolArgumentPosition
        public let value: Any
        public let valueType: any Any.Type
        
        public var invocationComponents: [InvocationComponent] {
            _ResolvedInvocationValueLowering
                .arguments(from: value)
                .elements
                .map { InvocationComponent.positionalArgument($0) }
        }
    }
    
    /// A resolved option.
    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Option: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, _ResolvedCommandLineToolInvocationArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let defaultPosition: _CommandLineToolArgumentPosition
        public let conversion: _CommandLineToolOptionKeyConversion
        public let name: String
        public let separator: _CommandLineToolParameterKeyValueSeparator
        public let multiValueEncoding: MultiValueParameterEncodingStrategy?
        public let value: Any
        public let valueType: any Any.Type
        
        public var invocationComponents: [InvocationComponent] {
            if let optionValue = value as? any OptionalProtocol, optionValue.isNil {
                return []
            }
            
            let key = CommandLineToolInvocation.Argument(conversion.argumentKey(for: name))
            
            if let multiValueEncoding {
                let values = _ResolvedInvocationValueLowering.arguments(from: value)
                
                guard !values.isEmpty else {
                    return []
                }
                
                switch multiValueEncoding {
                    case .spaceSeparated:
                        assert(
                            separator == .space,
                            "key value separator conflicts with the multi value encoding strategy. You must specify set both to `.space`."
                        )
                        return [
                            .option(
                                key: key,
                                separator: separator,
                                values: values,
                                multiValueEncoding: multiValueEncoding
                            )
                        ]
                    case .singleValue:
                        return [
                            .option(
                                key: key,
                                separator: separator,
                                values: values,
                                multiValueEncoding: multiValueEncoding
                            )
                        ]
                }
            }
            
            if let argument = _ResolvedInvocationValueLowering.scalarArgument(from: value), !argument.rawValue.isEmpty {
                return [
                    .option(
                        key: key,
                        separator: separator,
                        values: [argument]
                    )
                ]
            } else {
                return []
            }
        }
    }
    
    /// A resolved boolean flag.
    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct BooleanFlag: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, _ResolvedCommandLineToolInvocationArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let defaultPosition: _CommandLineToolArgumentPosition
        public let conversion: _CommandLineToolOptionKeyConversion
        public let name: String
        public let inversion: _CommandLineToolFlagInversion?
        public let defaultBooleanValue: Bool?
        public let isOn: Bool?
        
        public var invocationComponents: [InvocationComponent] {
            guard let isOn else { return [] }
            
            if let inversion {
                return [
                    .flag(CommandLineToolInvocation.Argument(inversion.argument(conversion: conversion, name: name, value: isOn)))
                ]
            }
            
            if defaultBooleanValue != isOn {
                return [
                    .flag(CommandLineToolInvocation.Argument("\(conversion.argumentKey(for: name))"))
                ]
            } else {
                return []
            }
        }
    }
    
    /// A resolved simple flag.
    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct CounterFlag: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, _ResolvedCommandLineToolInvocationArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let defaultPosition: _CommandLineToolArgumentPosition
        public let conversion: _CommandLineToolOptionKeyConversion
        public let name: String
        public let count: Int
        public let isClustered: Bool
        
        public var invocationComponents: [InvocationComponent] {
            guard count > 0 else { return [] }
            
            if isClustered {
                return [
                    .flag(CommandLineToolInvocation.Argument("\(conversion.argumentKey(for: (0..<count).map({ _ in name }).joined()))"))
                ]
            }
            
            return (0..<count)
                .map { _ in "\(conversion.argumentKey(for: name))" }
                .map { InvocationComponent.flag(CommandLineToolInvocation.Argument($0)) }
        }
    }
    
    /// A resolved custom flag.
    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct CustomFlag: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, _ResolvedCommandLineToolInvocationArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let defaultPosition: _CommandLineToolArgumentPosition
        
        public let value: Any
        public let valueType: any Any.Type
        
        public var invocationComponents: [InvocationComponent] {
            if let optionValue = value as? any OptionalProtocol, optionValue.isNil {
                return []
            }
            
            if let values = Self.optionKeyConvertibleValues(from: value) {
                return values
                    .map { $0.conversion.argumentKey(for: $0.name) }
                    .map { InvocationComponent.flag(CommandLineToolInvocation.Argument($0)) }
            } else {
                return []
            }
        }
        
        private static func optionKeyConvertibleValues(
            from value: Any
        ) -> [any CLT.OptionKeyConvertible]? {
            if let value = value as? any CLT.OptionKeyConvertible {
                return [value]
            }
            
            let mirror = Mirror(reflecting: value)
            
            if mirror.displayStyle == .optional {
                guard let child = mirror.children.first else {
                    return nil
                }
                
                return optionKeyConvertibleValues(from: child.value)
            }
            
            guard mirror.displayStyle == .collection else {
                return nil
            }
            
            let values = mirror.children.compactMap { child -> (any CLT.OptionKeyConvertible)? in
                child.value as? any CLT.OptionKeyConvertible
            }
            
            return values.count == mirror.children.count ? values : nil
        }
    }
    
    /// A resolved subcommand.
    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Subcommand: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Identifiable {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let name: CommandLineTool.Name
        public let _resolvedDescription: _ResolvedCommandLineToolDescription
        
        public var description: String {
            name.rawValue
        }
        
        public var debugDescription: String {
            "Subcommand(name: \(String(reflecting: name)), id: \(id.debugDescription))"
        }
        
        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "id": id,
                    "name": name,
                    "resolvedDescription": _resolvedDescription
                ],
                displayStyle: .struct
            )
        }
    }
    
    public var commandName: CommandLineTool.Name
    public var arguments: ResolvedArguments
    public var subcommands: ResolvedSubcommands
    
    public init(
        commandName: CommandLineTool.Name,
        arguments: ResolvedArguments,
        subcommands: ResolvedSubcommands
    ) {
        self.commandName = commandName
        self.arguments = arguments
        self.subcommands = subcommands
    }
    
    public init(
        commandName: String,
        arguments: ResolvedArguments,
        subcommands: ResolvedSubcommands
    ) {
        self.init(
            commandName: CommandLineTool.Name(commandName),
            arguments: arguments,
            subcommands: subcommands
        )
    }
    
    public var inheritedArguments: ResolvedArguments {
        arguments.filter({ $0.id.commandName != commandName })
    }
    public var localArguments: ResolvedArguments {
        arguments.filter({ $0.id.commandName == commandName })
    }
    
    public mutating func mergeInPlace(with other: _ResolvedCommandLineToolDescription) {
        arguments.append(contentsOf: other.arguments)
        subcommands.append(contentsOf: other.subcommands)
    }
    
    public var description: String {
        commandName.rawValue
    }
    
    public var debugDescription: String {
        "_ResolvedCommandLineToolDescription(commandName: \(String(reflecting: commandName)), arguments: \(arguments.count), subcommands: \(subcommands.count))"
    }
    
    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "commandName": commandName,
                "arguments": arguments,
                "subcommands": subcommands
            ],
            displayStyle: .struct
        )
    }
}
