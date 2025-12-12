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
        let mainCommandName = type(of: self)._commandName
                
        let mirror = Mirror(reflecting: self)
        
        var _resolved: [_ResolvedArgument] = []
        
        for child in mirror.children {
            if let parameter = child.value as? (any _CommandLineToolParameterProtocol) {
                _resolved.append(contentsOf: _resolveParameter(parameter, in: context))
            } else if let flag = child.value as? (any _CommandLineToolFlagProtocol) {
                _resolved.append(contentsOf: _resolveFlag(flag, in: context))
            } else if let subcommand = child.value as? (any _CommandLineToolSubcommandProtocol) {
                _resolved.append(contentsOf: _resolveSubcommand(subcommand, label: child.label, in: context))
            }
        }

        var resolvedArguments: [_AnyResolvedCommandLineToolArgument] = []
        resolvedArguments.reserveCapacity(_resolved.count)
        
        for (index, seed) in _resolved.enumerated() {
            resolvedArguments.append(seed._makeResolvedArgument(index: index))
        }
        
        let arguments = IdentifierIndexingArrayOf(resolvedArguments)
        
        return _ResolvedCommandLineToolDescription(
            mainCommandName: mainCommandName,
            arguments: arguments
        )
    }
    
    private func _resolveSubcommand(
        _ subcommand: any _CommandLineToolSubcommandProtocol,
        label: String?,
        in context: _CommandLineToolResolutionContext
    ) -> [_ResolvedArgument] {
        guard var rawName = label, !rawName.isEmpty else {
            return []
        }
        
        if rawName.hasPrefix("_") {
            rawName.removeFirst()
        }
        
        let name = rawName.lowercased()
        
        let wrappedValue = subcommand.wrappedValue
        let wrappedMirror = Mirror(reflecting: wrappedValue)
        
        guard let optionGroup = wrappedMirror.children
            .first(where: { $0.label == "optionGroup" })?
            .value as? CommandLineToolCommand else {
            return []
        }
        
        let optionMirror = Mirror(reflecting: optionGroup)
        var resolvedArguments: [_ResolvedArgument] = []
        
        for child in optionMirror.children {
            if let parameter = child.value as? (any _CommandLineToolParameterProtocol) {
                resolvedArguments.append(contentsOf: _resolveParameter(parameter, in: context))
            } else if let flag = child.value as? (any _CommandLineToolFlagProtocol) {
                resolvedArguments.append(contentsOf: _resolveFlag(flag, in: context))
            } else if let nestedSubcommand = child.value as? (any _CommandLineToolSubcommandProtocol) {
                resolvedArguments.append(contentsOf: _resolveSubcommand(nestedSubcommand, label: child.label, in: context))
            }
        }
        
        func returnType<S: _CommandLineToolSubcommandProtocol>(of subcommand: S) -> S.Result.Type {
            S.Result.self
        }
        let subcommandSeed: _ResolvedArgument = .subcommand(
            name: name,
            resolvedArguments: resolvedArguments.enumerated().map({ $1._makeResolvedArgument(index: $0) }),
            returnType: _openExistential(subcommand, do: returnType(of:)),
            argumentString: name
        )
        
        return [subcommandSeed]
    }

    private func _resolveFlag(
        _ flag: any _CommandLineToolFlagProtocol,
        in context: _CommandLineToolResolutionContext
    ) -> [_ResolvedArgument] {
        guard let unwrappedValue = _unwrappedValue(flag.wrappedValue) else {
            return []
        }
        
        switch flag._representaton {
            case .custom:
                if let array = unwrappedValue as? Array<any CLT.OptionKeyConvertible> {
                    return array.map { option in
                        let conversion = _effectiveConversion(
                            explicit: option.conversion,
                            name: option.name,
                            context: context
                        )
                        let keyString = conversion.argumentKey(for: option.name)
                        return .flag(
                            conversion: conversion,
                            name: option.name,
                            inversion: .prefixedNo,
                            isOn: true,
                            argumentString: keyString
                        )
                    }
                } else if let option = unwrappedValue as? any CLT.OptionKeyConvertible {
                    let conversion = _effectiveConversion(
                        explicit: option.conversion,
                        name: option.name,
                        context: context
                    )
                    let keyString = conversion.argumentKey(for: option.name)
                    return [
                        .flag(
                            conversion: conversion,
                            name: option.name,
                            inversion: .prefixedNo,
                            isOn: true,
                            argumentString: keyString
                        )
                    ]
                } else {
                    return []
                }
            case .counter(let explicitConversion, let name):
                guard let count = unwrappedValue as? Int, count > 0 else {
                    return []
                }
                
                let conversion = _effectiveConversion(
                    explicit: explicitConversion,
                    name: name,
                    context: context
                )
                
                let argumentString: String
                if conversion == .hyphenPrefixed, name.count == 1 {
                    argumentString = conversion.prefix + String(repeating: name, count: count)
                } else {
                    let key = conversion.argumentKey(for: name)
                    argumentString = Array(repeating: key, count: count).joined(separator: " ")
                }
                
                return [
                    .flag(
                        conversion: conversion,
                        name: name,
                        inversion: .prefixedNo,
                        isOn: true,
                        argumentString: argumentString
                    )
                ]
            case .boolean(let explicitConversion, let name, let defaultValue):
                guard let boolValue = unwrappedValue as? Bool else {
                    return []
                }
                
                guard boolValue != defaultValue else {
                    return []
                }
                
                let conversion = _effectiveConversion(
                    explicit: explicitConversion,
                    name: name,
                    context: context
                )
                
                let keyString = conversion.argumentKey(for: name)
                
                return [
                    .flag(
                        conversion: conversion,
                        name: name,
                        inversion: .prefixedNo,
                        isOn: boolValue,
                        argumentString: keyString
                    )
                ]
            case .optionalBoolean(let explicitConversion, let name, let inversion):
                guard let boolValue = unwrappedValue as? Bool else {
                    return []
                }
                
                let conversion = _effectiveConversion(
                    explicit: explicitConversion,
                    name: name,
                    context: context
                )
                
                let argumentString = inversion.argument(
                    conversion: conversion,
                    name: name,
                    value: boolValue
                )
                
                return [
                    .flag(
                        conversion: conversion,
                        name: name,
                        inversion: inversion,
                        isOn: boolValue,
                        argumentString: argumentString
                    )
                ]
        }
    }
    
    private func _resolveParameter(
        _ parameter: any _CommandLineToolParameterProtocol,
        in context: _CommandLineToolResolutionContext
    ) -> [_ResolvedArgument] {
        guard let unwrappedValue = _unwrappedValue(parameter.wrappedValue) else {
            return []
        }
        
        if let name = parameter.name {
            let conversion = _effectiveConversion(
                explicit: parameter.optionKeyConversion,
                name: name,
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
                                
                return [
                    .option(
                        conversion: conversion,
                        name: name,
                        separator: parameter.keyValueSeparator,
                        value: .left(values),
                        isVariadic: true,
                        argumentString: argumentString
                    )
                ]
            } else if let value = unwrappedValue as? (any CLT.ArgumentValueConvertible) {
                let keyString = conversion.argumentKey(for: name)
                let argumentString = keyString + parameter.keyValueSeparator.rawValue + value.argumentValue
                
                return [
                    .option(
                        conversion: conversion,
                        name: name,
                        separator: parameter.keyValueSeparator,
                        value: .right(value as CLT.ArgumentValueConvertible),
                        isVariadic: false,
                        argumentString: argumentString
                    )
                ]
            } else {
                return []
            }
        } else {
            if let array = unwrappedValue as? Array<any CLT.ArgumentValueConvertible> {
                return array.map {
                    .argument(
                        value: $0 as CLT.ArgumentValueConvertible,
                        argumentString: $0.argumentValue
                    )
                }
            } else if let value = unwrappedValue as? (any CLT.ArgumentValueConvertible) {
                return [
                    .argument(
                        value: value as CLT.ArgumentValueConvertible,
                        argumentString: value.argumentValue
                    )
                ]
            } else {
                return []
            }
        }
    }
}

extension AnyCommandLineTool {
    fileprivate enum _ResolvedArgument {
        case argument(value: CLT.ArgumentValueConvertible, argumentString: String)
        case option(
            conversion: _CommandLineToolOptionKeyConversion,
            name: String,
            separator: _CommandLineToolParameterKeyValueSeparator,
            value: Either<[CLT.ArgumentValueConvertible], CLT.ArgumentValueConvertible>,
            isVariadic: Bool,
            argumentString: String
        )
        case flag(
            conversion: _CommandLineToolOptionKeyConversion,
            name: String,
            inversion: _CommandLineToolFlagInversion,
            isOn: Bool,
            argumentString: String
        )
        case subcommand(
            name: String,
            resolvedArguments: _ResolvedCommandLineToolDescription.ResolvedArguments,
            returnType: Any.Type,
            argumentString: String
        )
        
        func _makeResolvedArgument(index: Int) -> _AnyResolvedCommandLineToolArgument {
            switch self {
                case .argument(let value, let argumentString):
                    let argument = _ResolvedCommandLineToolDescription.Argument(
                        id: .init(index: index, argument: argumentString),
                        value: value
                    )
                    return .init(_erasing: argument)
                case .option(let conversion, let name, let separator, let value, let isVariadic, let argumentString):
                    let option = _ResolvedCommandLineToolDescription.Option(
                        id: .init(index: index, argument: argumentString),
                        convertion: conversion,
                        name: name,
                        separator: separator,
                        value: value,
                        isVariadic: isVariadic
                    )
                    return .init(_erasing: option)
                case .flag(let conversion, let name, let inversion, let isOn, let argumentString):
                    let flag = _ResolvedCommandLineToolDescription.Flag(
                        id: .init(index: index, argument: argumentString),
                        conversion: conversion,
                        name: name,
                        inversion: inversion,
                        isOn: isOn
                    )
                    return .init(_erasing: flag)
                case .subcommand(let name, let resolvedArguments, let returnType, let argumentString):
                    let subcommand = _ResolvedCommandLineToolDescription.Subcommand(
                        id: .init(index: index, argument: argumentString),
                        name: name,
                        resolvedArguments: resolvedArguments,
                        returnType: returnType
                    )
                    return .init(_erasing: subcommand)
            }
        }
    }
    
}

// MARK: - Helpers

extension AnyCommandLineTool {
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
        name: String,
        context: _CommandLineToolResolutionContext
    ) -> _CommandLineToolOptionKeyConversion {
        explicit ?? keyConversion ?? context.defaultKeyConversion ?? defaultKeyConversion(name)
    }
    
    private func defaultKeyConversion(_ name: String) -> _CommandLineToolOptionKeyConversion {
        name.count > 1 ? .doubleHyphenPrefixed : .hyphenPrefixed
    }
}
