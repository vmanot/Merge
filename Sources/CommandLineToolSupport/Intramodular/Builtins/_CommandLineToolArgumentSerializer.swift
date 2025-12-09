//
//  CommandLineToolArgumentSerializing.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/9.
//

import Foundation
import Swallow

struct _CommandLineToolArgumentSerializer {
    
}

// MARK: - `@Parameter` Serializer

extension _CommandLineToolArgumentSerializer {
    static func serialize(_ parameter: any _CommandLineToolParameterProtocol) -> String? {
        if let optionalValue = parameter.wrappedValue as? (any OptionalProtocol),
            optionalValue.isNil {
            return nil // Skip this parameter if the value is empty.
        }
        
        var argument = ""
        
        func _singleValueParameter(
            key: _CommandLineToolOptionKey?,
            keyValueSeparator: _CommandLineToolParameterKeyValueSeparator,
            value: any CLT.ArgumentValueConvertible,
        ) -> String {
            var argument = ""
            if let key {
                argument += key.argumentValue
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
                                key: parameter.key,
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
                    if let key = parameter.key {
                        argument += key.argumentValue
                    }
                    argument += array.map(\.argumentValue).joined(separator: " ")
            }
        } else {
            let value = parameter.wrappedValue as? (any CLT.ArgumentValueConvertible)
            guard let value else { return nil }
            
            argument = _singleValueParameter(
                key: parameter.key,
                keyValueSeparator: parameter.keyValueSeparator,
                value: value
            )
        }
        
        return argument
    }
}

// MARK: - `@Flag` Serializer

extension _CommandLineToolArgumentSerializer {
    static func serialize(_ flag: any _CommandLineToolFlagProtocol) -> String? {
        if let optionalValue = flag.wrappedValue as? (any OptionalProtocol),
            optionalValue.isNil {
            return nil // Skip this flag if the value is empty.
        }
        
        var argument = flag.key?.argumentValue ?? ""
        
        if let booleanValue = flag.wrappedValue as? Bool {
            if let inversion = flag.inversion,
               let inserted = inversion.insertionText(flagValue: booleanValue) {
                // support inversion, we can safely add argument.
                switch flag.key {
                    case .doubleHyphenPrefixed:
                        argument.insert(
                            contentsOf: "\(inserted)-",
                            at: argument.index(atDistance: /* -- */ 2)
                        )
                    case .hyphenPrefixed:
                        argument.insert(
                            contentsOf: "\(inserted)-",
                            at: argument.index(atDistance: /* - */ 1)
                        )
                    default:
                        break
                }
            } else if flag.wrappedValue.eraseToAnyEquatable() == flag.defaultValue.eraseToAnyEquatable() {
                // does not support inversion, only emit the flag if it's not equal to the default value.
                return nil
            }
        } else if let repeatCount = flag.wrappedValue as? Int {
            argument = [String](repeating: argument, count: repeatCount)
                .joined(separator: " ")
        } else if let flagSet = flag.wrappedValue as? Array<(any CLT.OptionKeyConvertible)> {
            argument = flagSet.map(\.optionKey.argumentValue).joined(separator: " ")
        } else if let argumentConvertibleFlag = flag.wrappedValue as? (any CLT.OptionKeyConvertible) {
            argument = argumentConvertibleFlag.optionKey.argumentValue
        }
        
        return argument
    }
}
