//
//  AnyCommandLineTool+Resolve.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/12.
//

import Foundation
import Swallow

extension AnyCommandLineTool {
    public func resolve(in context: _CommandLineToolResolutionContext) -> _ResolvedCommandLineToolDescription {
        let commandChain = _commandChainFromRoot()
        let mainCommandName = commandChain
            .map { type(of: $0).commandName }
            .joined(separator: " ")
        
        var resolvedArguments: [_AnyResolvedCommandLineToolArgument] = []
        var argumentIndex: Int = 0
        
        for tool in commandChain {
            let mirror = Mirror(reflecting: tool)
            
            for child in mirror.children {
                if let parameter = child.value as? (any _CommandLineToolParameterProtocol) {
                    guard let unwrappedValue = _unwrappedValue(parameter.wrappedValue) else {
                        continue
                    }
                    
                    if let name = parameter.name {
                        let conversion = _effectiveConversion(
                            explicit: parameter.optionKeyConversion,
                            tool: tool,
                            context: context
                        )
                        
                        if let strategy = parameter.multiValueEncodingStrategy,
                           let array = unwrappedValue as? Array<any CLT.ArgumentValueConvertible> {
                            let values: [CLT.ArgumentValueConvertible] = array.map { $0 as CLT.ArgumentValueConvertible }
                            let keyString = conversion.argumentKey(for: name)
                            
                            let argumentString: String = {
                                switch strategy {
                                    case .singleValue:
                                        return array
                                            .map { value in
                                                keyString + parameter.keyValueSeparator.rawValue + value.argumentValue
                                            }
                                            .joined(separator: " ")
                                    case .spaceSeparated:
                                        assert(
                                            parameter.keyValueSeparator == .space,
                                            "key value separator conflicts with the multi value encoding strategy. You must specify set both to `.space`."
                                        )
                                        let joinedValues = array.map(\.argumentValue).joined(separator: " ")
                                        return joinedValues.isEmpty ? keyString : (keyString + " " + joinedValues)
                                }
                            }()
                            
                            let option = _ResolvedCommandLineToolDescription.Option(
                                id: .init(
                                    index: argumentIndex,
                                    argument: argumentString
                                ),
                                convertion: conversion,
                                name: name,
                                separator: parameter.keyValueSeparator,
                                value: .left(values),
                                isVariadic: true
                            )
                            
                            resolvedArguments.append(.init(_erasing: option))
                            argumentIndex += 1
                        } else if let value = unwrappedValue as? (any CLT.ArgumentValueConvertible) {
                            let keyString = conversion.argumentKey(for: name)
                            let argumentString = keyString + parameter.keyValueSeparator.rawValue + value.argumentValue
                            
                            let option = _ResolvedCommandLineToolDescription.Option(
                                id: .init(
                                    index: argumentIndex,
                                    argument: argumentString
                                ),
                                convertion: conversion,
                                name: name,
                                separator: parameter.keyValueSeparator,
                                value: .right(value as CLT.ArgumentValueConvertible),
                                isVariadic: false
                            )
                            
                            resolvedArguments.append(.init(_erasing: option))
                            argumentIndex += 1
                        }
                    } else {
                        if let array = unwrappedValue as? Array<any CLT.ArgumentValueConvertible> {
                            for value in array {
                                let argument = _ResolvedCommandLineToolDescription.Argument(
                                    id: .init(
                                        index: argumentIndex,
                                        argument: value.argumentValue
                                    ),
                                    value: value as CLT.ArgumentValueConvertible
                                )
                                
                                resolvedArguments.append(.init(_erasing: argument))
                                argumentIndex += 1
                            }
                        } else if let value = unwrappedValue as? (any CLT.ArgumentValueConvertible) {
                            let argument = _ResolvedCommandLineToolDescription.Argument(
                                id: .init(
                                    index: argumentIndex,
                                    argument: value.argumentValue
                                ),
                                value: value as CLT.ArgumentValueConvertible
                            )
                            
                            resolvedArguments.append(.init(_erasing: argument))
                            argumentIndex += 1
                        }
                    }
                } else if let flag = child.value as? (any _CommandLineToolFlagProtocol) {
                    guard let unwrappedValue = _unwrappedValue(flag.wrappedValue) else {
                        continue
                    }
                    
                    switch flag._representaton {
                        case .custom:
                            if let array = unwrappedValue as? Array<any CLT.OptionKeyConvertible> {
                                for option in array {
                                    let conversion = _effectiveConversion(
                                        explicit: option.conversion,
                                        tool: tool,
                                        context: context
                                    )
                                    let keyString = conversion.argumentKey(for: option.name)
                                    
                                    let resolvedFlag = _ResolvedCommandLineToolDescription.Flag(
                                        id: .init(
                                            index: argumentIndex,
                                            argument: keyString
                                        ),
                                        conversion: conversion,
                                        name: option.name,
                                        inversion: .prefixedNo,
                                        isOn: true
                                    )
                                    
                                    resolvedArguments.append(.init(_erasing: resolvedFlag))
                                    argumentIndex += 1
                                }
                            } else if let option = unwrappedValue as? any CLT.OptionKeyConvertible {
                                let conversion = _effectiveConversion(
                                    explicit: option.conversion,
                                    tool: tool,
                                    context: context
                                )
                                let keyString = conversion.argumentKey(for: option.name)
                                
                                let resolvedFlag = _ResolvedCommandLineToolDescription.Flag(
                                    id: .init(
                                        index: argumentIndex,
                                        argument: keyString
                                    ),
                                    conversion: conversion,
                                    name: option.name,
                                    inversion: .prefixedNo,
                                    isOn: true
                                )
                                
                                resolvedArguments.append(.init(_erasing: resolvedFlag))
                                argumentIndex += 1
                            }
                        case .counter(let explicitConversion, let name):
                            guard let count = unwrappedValue as? Int, count > 0 else {
                                continue
                            }
                            
                            let conversion = _effectiveConversion(
                                explicit: explicitConversion,
                                tool: tool,
                                context: context
                            )
                            
                            let argumentString: String
                            if conversion == .hyphenPrefixed, name.count == 1 {
                                argumentString = conversion.prefix + String(repeating: name, count: count)
                            } else {
                                let key = conversion.argumentKey(for: name)
                                argumentString = Array(repeating: key, count: count).joined(separator: " ")
                            }
                            
                            let resolvedFlag = _ResolvedCommandLineToolDescription.Flag(
                                id: .init(
                                    index: argumentIndex,
                                    argument: argumentString
                                ),
                                conversion: conversion,
                                name: name,
                                inversion: .prefixedNo,
                                isOn: true
                            )
                            
                            resolvedArguments.append(.init(_erasing: resolvedFlag))
                            argumentIndex += 1
                        case .boolean(let explicitConversion, let name, let defaultValue):
                            guard let boolValue = unwrappedValue as? Bool else {
                                continue
                            }
                            
                            guard boolValue != defaultValue else {
                                continue
                            }
                            
                            let conversion = _effectiveConversion(
                                explicit: explicitConversion,
                                tool: tool,
                                context: context
                            )
                            
                            let keyString = conversion.argumentKey(for: name)
                            
                            let resolvedFlag = _ResolvedCommandLineToolDescription.Flag(
                                id: .init(
                                    index: argumentIndex,
                                    argument: keyString
                                ),
                                conversion: conversion,
                                name: name,
                                inversion: .prefixedNo,
                                isOn: boolValue
                            )
                            
                            resolvedArguments.append(.init(_erasing: resolvedFlag))
                            argumentIndex += 1
                        case .optionalBoolean(let explicitConversion, let name, let inversion):
                            guard let boolValue = unwrappedValue as? Bool else {
                                continue
                            }
                            
                            let conversion = _effectiveConversion(
                                explicit: explicitConversion,
                                tool: tool,
                                context: context
                            )
                            
                            let argumentString = inversion.argument(
                                conversion: conversion,
                                name: name,
                                value: boolValue
                            )
                            
                            let resolvedFlag = _ResolvedCommandLineToolDescription.Flag(
                                id: .init(
                                    index: argumentIndex,
                                    argument: argumentString
                                ),
                                conversion: conversion,
                                name: name,
                                inversion: inversion,
                                isOn: boolValue
                            )
                            
                            resolvedArguments.append(.init(_erasing: resolvedFlag))
                            argumentIndex += 1
                    }
                } else if child.value is (any _CommandLineToolSubcommandProtocol) {
                    // Subcommands are currently treated as part of the command chain and do not contribute arguments here.
                    continue
                }
            }
        }
        
        let arguments = try! IdentifierIndexingArrayOf(resolvedArguments)
        
        return _ResolvedCommandLineToolDescription(
            mainCommandName: mainCommandName,
            arguments: arguments
        )
    }
}

// MARK: - Helpers

extension AnyCommandLineTool {
    private func _commandChainFromRoot() -> [AnyCommandLineTool] {
        var chain: [AnyCommandLineTool] = [self]
        var current = self
        
        while let parent = current.parent {
            chain.append(parent)
            current = parent
        }
        
        return chain.reversed()
    }
    
    private func _unwrappedValue(_ value: Any) -> Any? {
        if let optionalValue = value as? (any OptionalProtocol) {
            if optionalValue.isNil {
                return nil
            }
            return optionalValue._wrapped
        }
        
        return value
    }
    
    private func _effectiveConversion(
        explicit: _CommandLineToolOptionKeyConversion?,
        tool: AnyCommandLineTool,
        context: _CommandLineToolResolutionContext
    ) -> _CommandLineToolOptionKeyConversion {
        explicit ?? tool.keyConversion ?? context.defaultKeyConversion ?? .doubleHyphenPrefixed
    }
    
    private func defaultKeyConversion(_ name: String) -> _CommandLineToolOptionKeyConversion {
        name.count > 1 ? .doubleHyphenPrefixed : .hyphenPrefixed
    }
}
