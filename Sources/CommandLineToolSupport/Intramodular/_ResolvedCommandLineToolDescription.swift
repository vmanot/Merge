//
//  _ResolvedCommandLineToolDescription.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/11.
//

import Foundation
import Swallow
import Collections

/// The most granular and "resolved" representation of a command-line tool within some context.
public struct _ResolvedCommandLineToolDescription: MergeOperatable {
    public struct ArgumentID: Hashable, Sendable {
        public let rawValue: String // the property name.
        public let commandName: String
    }
    
    public typealias ResolvedArguments = IdentifierIndexingArrayOf<_AnyResolvedCommandLineToolInvocationArgument>
    public typealias ResolvedSubcommands = IdentifierIndexingArrayOf<Subcommand>
    
    /// A resolved argument.
    public struct Argument: _ResolvedCommandLineToolInvocationArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let value: Any?
        public let valueType: any Any.Type
        
        public var invocationArgument: String? {
            // TODO: Support array
            (value as? CLT.ArgumentValueConvertible)?.argumentValue
        }
    }
    
    /// A resolved option.
    public struct Option: _ResolvedCommandLineToolInvocationArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let conversion: _CommandLineToolOptionKeyConversion
        public let name: String
        public let separator: _CommandLineToolParameterKeyValueSeparator
        public let multiValueEncoding: MultiValueParameterEncodingStrategy?
        public let value: Any
        public let valueType: any Any.Type

        public var invocationArgument: String? {
            if let optionValue = value as? any OptionalProtocol, optionValue.isNil {
                return nil
            }

            let key = conversion.argumentKey(for: name)

            if let multiValueEncoding {
                if let array = value as? [any CLT.ArgumentValueConvertible] {
                    switch multiValueEncoding {
                        case .spaceSeparated:
                            assert(
                                separator == .space,
                                "key value separator conflicts with the multi value encoding strategy. You must specify set both to `.space`."
                            )
                            let values = array.map(\.argumentValue)
                            return ([key] + values).joined(separator: " ")
                        case .singleValue:
                            return array
                                .map { "\(key)\(separator.rawValue)\($0.argumentValue)" }
                                .joined(separator: " ")
                    }
                } else {
                    return nil
                }
            }

            if let convertible = value as? CLT.ArgumentValueConvertible, !convertible.argumentValue.isEmpty {
                return "\(key)\(separator.rawValue)\(convertible.argumentValue)"
            } else {
                return nil
            }
        }
    }
    
    /// A resolved boolean flag.
    public struct BooleanFlag: _ResolvedCommandLineToolInvocationArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let conversion: _CommandLineToolOptionKeyConversion
        public let name: String
        public let inversion: _CommandLineToolFlagInversion?
        public let defaultBooleanValue: Bool?
        public let isOn: Bool?
        
        public var invocationArgument: String? {
            guard let isOn else { return nil }
            
            if let inversion {
                return inversion.argument(conversion: conversion, name: name, value: isOn)
            } else {
                return if defaultBooleanValue != isOn {
                    "\(conversion.argumentKey(for: name))"
                } else {
                    nil
                }
            }
        }
    }
    
    /// A resolved simple flag.
    public struct CounterFlag: _ResolvedCommandLineToolInvocationArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let conversion: _CommandLineToolOptionKeyConversion
        public let name: String
        public let count: Int
        public let isClustered: Bool
        
        public var invocationArgument: String? {
            guard count > 0 else { return nil }
            
            return if isClustered {
                "\(conversion.argumentKey(for: (0..<count).map({ _ in name }).joined()))"
            } else {
                (0..<count)
                    .map({ _ in "\(conversion.argumentKey(for: name))" })
                    .joined(separator: " ")
            }
        }
    }
    
    /// A resolved custom flag.
    public struct CustomFlag: _ResolvedCommandLineToolInvocationArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let conversion: _CommandLineToolOptionKeyConversion?
        public let value: Any
        public let valueType: any Any.Type
        
        public var invocationArgument: String? {
            if let optionValue = value as? any OptionalProtocol, optionValue.isNil {
                return nil
            }
            
            // FIXME: add support for custom flag array.
            guard let conversion else { return nil }
            return (value as? CLT.OptionKeyConvertible).flatMap {
                conversion.argumentKey(for: $0.name)
            }
        }
    }
    
    /// A resolved subcommand.
    public struct Subcommand: Identifiable {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let name: String
        public let _resolvedDescription: _ResolvedCommandLineToolDescription
    }
    
    public var toolName: String
    public var arguments: ResolvedArguments
    public var subcommands: ResolvedSubcommands
    
    public var inheritedArguments: ResolvedArguments {
        arguments.filter({ $0.id.commandName != toolName })
    }
    public var localArguments: ResolvedArguments {
        arguments.filter({ $0.id.commandName == toolName })
    }
    
    public mutating func mergeInPlace(with other: _ResolvedCommandLineToolDescription) {
        arguments.append(contentsOf: other.arguments)
        subcommands.append(contentsOf: other.subcommands)
    }
}

public protocol _ResolvedCommandLineToolInvocationArgument {
    var id: _ResolvedCommandLineToolDescription.ArgumentID { get }
    var invocationArgument: String? { get }
}

// MARK: - Type erasing

extension _ResolvedCommandLineToolInvocationArgument {
    package func erasedToAnyResolvedCommandLineToolInvocationArgument() -> _AnyResolvedCommandLineToolInvocationArgument {
        .init(_erasing: self)
    }
}

public struct _AnyResolvedCommandLineToolInvocationArgument: _UnwrappableTypeEraser, _ResolvedCommandLineToolInvocationArgument, Identifiable {
    public typealias _UnwrappedBaseType = any _ResolvedCommandLineToolInvocationArgument
    
    public let base: any _ResolvedCommandLineToolInvocationArgument
    
    public var id: _ResolvedCommandLineToolDescription.ArgumentID {
        base.id
    }
    
    public var invocationArgument: String? {
        base.invocationArgument
    }
    
    public init(_erasing x: any _ResolvedCommandLineToolInvocationArgument) {
        self.base = x
    }
    
    public func _unwrapBase() -> any _ResolvedCommandLineToolInvocationArgument {
        base
    }
}
