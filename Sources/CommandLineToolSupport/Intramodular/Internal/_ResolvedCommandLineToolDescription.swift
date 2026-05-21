//
// Copyright (c) Vatsal Manot
//


import Foundation
import Swallow
import Collections

/// The most granular and "resolved" representation of a command-line tool within some context.
public struct _ResolvedCommandLineToolDescription: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, MergeOperatable {
    public struct ArgumentID: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
        public let rawValue: String // the property name.
        public let commandName: String
        
        public init(
            rawValue: String,
            commandName: String
        ) {
            self.rawValue = rawValue
            self.commandName = commandName
        }
        
        public var description: String {
            "\(commandName).\(rawValue)"
        }
        
        public var debugDescription: String {
            "ArgumentID(rawValue: \(String(reflecting: rawValue)), commandName: \(String(reflecting: commandName)))"
        }
        
        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "rawValue": rawValue,
                    "commandName": commandName
                ],
                displayStyle: .struct
            )
        }
    }
    
    public struct InvocationComponent: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
        public enum Kind: Hashable, Sendable {
            case positionalArgument
            case option
            case flag
        }
        
        public var kind: Kind
        public var key: CommandLineToolInvocation.Argument?
        public var separator: _CommandLineToolParameterKeyValueSeparator?
        public var values: [CommandLineToolInvocation.Argument]
        public var multiValueEncoding: MultiValueParameterEncodingStrategy?
        
        public init(
            kind: Kind,
            key: CommandLineToolInvocation.Argument? = nil,
            separator: _CommandLineToolParameterKeyValueSeparator? = nil,
            values: [CommandLineToolInvocation.Argument],
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
            Self(kind: .positionalArgument, values: [value])
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
                values: values,
                multiValueEncoding: multiValueEncoding
            )
        }
        
        public static func flag(
            _ value: CommandLineToolInvocation.Argument
        ) -> Self {
            Self(kind: .flag, values: [value])
        }
        
        public var invocationArgumentValues: [CommandLineToolInvocation.Argument] {
            switch kind {
                case .positionalArgument, .flag:
                    return values
                case .option:
                    guard let key, let separator, !values.isEmpty else {
                        return []
                    }
                    
                    if multiValueEncoding == .spaceSeparated {
                        return [key] + values
                    }
                    
                    if multiValueEncoding == .singleValue, separator == .space {
                        return values.flatMap { [key, $0] }
                    }
                    
                    if separator == .space, values.count == 1 {
                        return [key, values[0]]
                    }
                    
                    return values.map { value in
                        CommandLineToolInvocation.Argument("\(key.rawValue)\(separator.rawValue)\(value.rawValue)")
                    }
            }
        }
        
        public var publicInvocationComponent: CommandLineToolInvocation.Component {
            switch kind {
                case .positionalArgument:
                    return CommandLineToolInvocation.Component(
                        kind: .positionalArgument,
                        arguments: CommandLineToolInvocation.Arguments(values)
                    )
                case .flag:
                    return CommandLineToolInvocation.Component(
                        kind: .flag,
                        arguments: CommandLineToolInvocation.Arguments(values)
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
    
    public typealias ResolvedArguments = IdentifierIndexingArrayOf<_AnyResolvedCommandLineToolInvocationArgument>
    public typealias ResolvedSubcommands = IdentifierIndexingArrayOf<Subcommand>
    
    /// A resolved argument.
    public struct Argument: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, _ResolvedCommandLineToolInvocationArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let defaultPosition: _CommandLineToolArgumentPosition
        public let value: Any
        public let valueType: any Any.Type
        
        public var invocationComponents: [InvocationComponent] {
            if let optionValue = value as? any OptionalProtocol, optionValue.isNil {
                return []
            }
            
            if let array = value as? [any CLT.ArgumentValueConvertible] {
                return array
                    .map(\.argumentValue)
                    .filter { !$0.isEmpty }
                    .map { InvocationComponent.positionalArgument(CommandLineToolInvocation.Argument($0)) }
            }
            
            guard let argument = (value as? CLT.ArgumentValueConvertible)?.argumentValue else {
                return []
            }
            
            return argument.isEmpty ? [] : [
                InvocationComponent.positionalArgument(CommandLineToolInvocation.Argument(argument))
            ]
        }
    }
    
    /// A resolved option.
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
                if let array = value as? [any CLT.ArgumentValueConvertible] {
                    let values = array
                        .map(\.argumentValue)
                        .filter { !$0.isEmpty }
                        .map { CommandLineToolInvocation.Argument($0) }
                    
                    switch multiValueEncoding {
                        case .spaceSeparated:
                            assert(
                                separator == .space,
                                "key value separator conflicts with the multi value encoding strategy. You must specify set both to `.space`."
                            )
                            return values.isEmpty ? [] : [
                                .option(
                                    key: key,
                                    separator: separator,
                                    values: values,
                                    multiValueEncoding: multiValueEncoding
                                )
                            ]
                        case .singleValue:
                            return values.isEmpty ? [] : [
                                .option(
                                    key: key,
                                    separator: separator,
                                    values: values,
                                    multiValueEncoding: multiValueEncoding
                                )
                            ]
                    }
                } else {
                    return []
                }
            }
            
            if let convertible = value as? CLT.ArgumentValueConvertible, !convertible.argumentValue.isEmpty {
                return [
                    .option(
                        key: key,
                        separator: separator,
                        values: [CommandLineToolInvocation.Argument(convertible.argumentValue)]
                    )
                ]
            } else {
                return []
            }
        }
    }
    
    /// A resolved boolean flag.
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
            
            guard mirror.displayStyle == .collection || mirror.displayStyle == .set else {
                return nil
            }
            
            let values = mirror.children.compactMap { child -> (any CLT.OptionKeyConvertible)? in
                child.value as? any CLT.OptionKeyConvertible
            }
            
            return values.count == mirror.children.count ? values : nil
        }
    }
    
    /// A resolved subcommand.
    public struct Subcommand: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Identifiable {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let name: String
        public let _resolvedDescription: _ResolvedCommandLineToolDescription
        
        public var description: String {
            name
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
    
    public var commandName: String
    public var arguments: ResolvedArguments
    public var subcommands: ResolvedSubcommands
    
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
        commandName
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
