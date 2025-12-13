//
//  _CommandLineToolArgumentBuilder.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/13.
//

import Foundation
import Swallow

struct _CommandLineToolArgumentBuilder {
    var command: CommandLineToolCommand
    
    func buildCommandInvocation(operation: String? = nil) -> String {
        let mirror = Mirror(reflecting: command)
        var components = [command._commandName]
        
        if let operation {
            components.append(operation)
        }
        
        for child in mirror.children {
            if let parameter = child.value as? (any _CommandLineToolParameterProtocol),
               let component = _build(parameter) {
                components.append(component)
            } else if let flag = child.value as? (any _CommandLineToolFlagProtocol),
                      let component = _build(flag) {
                components.append(component)
            }
        }
        
        return components.filter({ !$0.isEmpty }).joined(separator: " ")
    }
    
    private func defaultKeyConversion(for name: String) -> _CommandLineToolOptionKeyConversion {
        command.keyConversion ?? _defaultKeyConversion(for: name)
    }
    
    private func _defaultKeyConversion(for name: String) -> _CommandLineToolOptionKeyConversion {
        name.count > 1 ? .doubleHyphenPrefixed : .hyphenPrefixed
    }
}

// MARK: - `@Parameter` Serializer

extension _CommandLineToolArgumentBuilder {
    private func _build(_ parameter: any _CommandLineToolParameterProtocol) -> String? {
        if let optionalValue = parameter.wrappedValue as? (any OptionalProtocol),
            optionalValue.isNil {
            return nil // Skip this parameter if the value is empty.
        }
        
        var argument = ""
        
        func _singleValueParameter(
            conversion: _CommandLineToolOptionKeyConversion?,
            name: String?,
            keyValueSeparator: _CommandLineToolParameterKeyValueSeparator,
            value: any CLT.ArgumentValueConvertible,
        ) -> String {
            var argument = ""
            if let name {
                argument += (conversion ?? defaultKeyConversion(for: name)).argumentKey(for: name)
            }
            argument += keyValueSeparator.rawValue
            argument += value.argumentValue
            return argument
        }
        
        if let multiValueEncodingStrategy = parameter.multiValueEncodingStrategy {
            let array = parameter.wrappedValue as? Array<(any CLT.ArgumentValueConvertible)>
            guard let array else { return nil }
            
            switch multiValueEncodingStrategy {
                case .singleValue:
                    argument = array
                        .map {
                            _singleValueParameter(
                                conversion: parameter.optionKeyConversion,
                                name: parameter.name,
                                keyValueSeparator: parameter.keyValueSeparator,
                                value: $0
                            )
                        }
                        .joined(separator: " ")
                case .spaceSeparated:
                    assert(
                        parameter.keyValueSeparator == .space,
                        "key value separator conflicts with the multi value encoding strategy. You must specify set both to `.space`."
                    )
                    if let conversion = parameter.optionKeyConversion, let name = parameter.name {
                        argument += conversion.argumentKey(for: name)
                    }
                    argument += array.map(\.argumentValue).joined(separator: " ")
            }
        } else {
            let value = parameter.wrappedValue as? (any CLT.ArgumentValueConvertible)
            guard let value else { return nil }
            
            argument = _singleValueParameter(
                conversion: parameter.optionKeyConversion,
                name: parameter.name,
                keyValueSeparator: parameter.keyValueSeparator,
                value: value
            )
        }
        
        return argument
    }
}

// MARK: - `@Flag` Serializer

extension _CommandLineToolArgumentBuilder {
    private func _build(_ flag: any _CommandLineToolFlagProtocol) -> String? {
        if let optionalValue = flag.wrappedValue as? (any OptionalProtocol),
           optionalValue.isNil {
            return nil // Skip this flag if the value is empty.
        }
        
        var argument: String?
        switch flag._representaton {
            case .custom:
                if let array = flag.wrappedValue as? Array<any CLT.OptionKeyConvertible> {
                    argument = array.map({
                        ($0.conversion ?? defaultKeyConversion(for: $0.name)).argumentKey(for: $0.name)
                    }).joined(separator: " ")
                } else if let optionKeyConvertible = flag.wrappedValue as? any CLT.OptionKeyConvertible {
                    argument = (optionKeyConvertible.conversion ?? defaultKeyConversion(for: optionKeyConvertible.name)).argumentKey(for: optionKeyConvertible.name)
                } else {
                    preconditionFailure("Custom type must conform to CLT.OptionKeyConvertible.")
                }
            case .counter(let conversion, let name):
                assert(flag.wrappedValue is Int, "Flag value type conflicts with the representation. Expect: Int, got: \(flag.wrappedValue.self)")
                let count = flag.wrappedValue as! Int
                if count > 0 {
                    argument = (0 ..< count).map({ _ in name }).joined()
                    switch conversion ?? defaultKeyConversion(for: name) {
                        case .doubleHyphenPrefixed:
                            argument!.insert(contentsOf: "--", at: argument!.startIndex)
                        case .hyphenPrefixed:
                            argument!.insert(contentsOf: "-", at: argument!.startIndex)
                        case .slashPrefixed:
                            argument!.insert(contentsOf: "/", at: argument!.startIndex)
                    }
                }
            case .optionalBoolean(let conversion, let name, let inversion): // always emits the flag based on inversion, nil value has already filtered at the very beginning.
                assert(flag.wrappedValue is Optional<Bool>, "Flag value type conflicts with the representation. Expect: Optional<Bool>, got: \(flag.wrappedValue.self)")
                let boolValue = (flag.wrappedValue as! Optional<Bool>)! // since nil value has been filtered at the beginning, it would be safe to unwrap it here
                argument = inversion.argument(conversion: conversion ?? defaultKeyConversion(for: name), name: name, value: boolValue)
            case .boolean(let conversion, let name, let defaultValue): // only emits the flag if current value is not default
                assert(flag.wrappedValue is Bool, "Flag value type conflicts with the representation. Expect: Bool, got: \(flag.wrappedValue.self)")
                let boolValue = flag.wrappedValue as! Bool
                if boolValue != defaultValue {
                    argument = (conversion ?? defaultKeyConversion(for: name)).argumentKey(for: name)
                }
        }
        
        return argument ?? ""
    }
}
