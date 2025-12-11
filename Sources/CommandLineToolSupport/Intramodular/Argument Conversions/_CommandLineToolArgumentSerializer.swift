//
//  CommandLineToolArgumentSerializing.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/9.
//

import Foundation
import Swallow

struct _CommandLineToolArgumentResolver {
    
}

// MARK: - `@Parameter` Serializer

extension _CommandLineToolArgumentResolver {
    static func serialize(_ parameter: any _CommandLineToolParameterProtocol) -> String? {
        fatalError(.unimplemented)
//        if let optionalValue = parameter.wrappedValue as? (any OptionalProtocol),
//            optionalValue.isNil {
//            return nil // Skip this parameter if the value is empty.
//        }
//        
//        var argument = ""
//        
//        func _singleValueParameter(
//            key: _CommandLineToolOptionKeyConversion?,
//            keyValueSeparator: _CommandLineToolParameterKeyValueSeparator,
//            value: any CLT.ArgumentValueConvertible,
//        ) -> String {
//            var argument = ""
//            if let key {
//                argument += key.argumentValue
//            }
//            argument += keyValueSeparator.rawValue
//            argument += value.argumentValue
//            return argument
//        }
//        
//        if let multiValueEncodingStrategy = parameter.multiValueEncodingStrategy {
//            let array = parameter.wrappedValue as? Array<(any CLT.ArgumentValueConvertible)>
//            guard let array else { return nil }
//            
//            switch multiValueEncodingStrategy {
//                case .singleValue:
//                    argument = array
//                        .map {
//                            _singleValueParameter(
//                                key: parameter.key,
//                                keyValueSeparator: parameter.keyValueSeparator,
//                                value: $0
//                            )
//                        }
//                        .joined(separator: " ")
//                case .spaceSeparated:
//                    assert(
//                        parameter.keyValueSeparator == .space,
//                        "key value separator conflicts with the multi value encoding strategy. You must specify set both to `.space`."
//                    )
//                    if let key = parameter.key {
//                        argument += key.argumentValue
//                    }
//                    argument += array.map(\.argumentValue).joined(separator: " ")
//            }
//        } else {
//            let value = parameter.wrappedValue as? (any CLT.ArgumentValueConvertible)
//            guard let value else { return nil }
//            
//            argument = _singleValueParameter(
//                key: parameter.key,
//                keyValueSeparator: parameter.keyValueSeparator,
//                value: value
//            )
//        }
//        
//        return argument
    }
}

// MARK: - `@Flag` Serializer

extension _CommandLineToolArgumentResolver {
    static func serialize(_ flag: any _CommandLineToolFlagProtocol) -> String? {
        fatalError(.unimplemented)
//        if let optionalValue = flag.wrappedValue as? (any OptionalProtocol),
//           optionalValue.isNil {
//            return nil // Skip this flag if the value is empty.
//        }
//        
//        var argument: String?
//        switch flag._representaton {
//            case .custom:
//                if let array = flag.wrappedValue as? Array<any CLT.OptionKeyConvertible> {
//                    argument = array.map(\.optionKey.argumentValue).joined(separator: " ")
//                } else if let optionKeyConvertible = flag.wrappedValue as? any CLT.OptionKeyConvertible {
//                    argument = optionKeyConvertible.optionKey.argumentValue
//                } else {
//                    preconditionFailure("Custom type must conform to CLT.OptionKeyConvertible.")
//                }
//            case .counter(let key):
//                assert(flag.wrappedValue is Int, "Flag value type conflicts with the representation. Expect: Int, got: \(flag.wrappedValue.self)")
//                let count = flag.wrappedValue as! Int
//                if count > 0 {
//                    argument = (0 ..< count).map({ _ in key.name }).joined()
//                    switch key {
//                        case .doubleHyphenPrefixed:
//                            argument!.insert(contentsOf: "--", at: argument!.startIndex)
//                        case .hyphenPrefixed:
//                            argument!.insert(contentsOf: "-", at: argument!.startIndex)
//                        case .slashPrefixed:
//                            argument!.insert(contentsOf: "/", at: argument!.startIndex)
//                    }
//                }
//            case .optionalBoolean(let key, let inversion): // always emits the flag based on inversion, nil value has already filtered at the very beginning.
//                assert(flag.wrappedValue is Optional<Bool>, "Flag value type conflicts with the representation. Expect: Optional<Bool>, got: \(flag.wrappedValue.self)")
//                let boolValue = (flag.wrappedValue as! Optional<Bool>)! // since nil value has been filtered at the beginning, it would be safe to unwrap it here
//                argument = inversion.argument(key, value: boolValue)
//            case .boolean(let key, let defaultValue): // only emits the flag if current value is not default
//                assert(flag.wrappedValue is Bool, "Flag value type conflicts with the representation. Expect: Bool, got: \(flag.wrappedValue.self)")
//                let boolValue = flag.wrappedValue as! Bool
//                if boolValue != defaultValue {
//                    argument = key.argumentValue
//                }
//        }
//        
//        return argument ?? ""
    }
}
