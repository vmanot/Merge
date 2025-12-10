//
//  _CommandLineToolFlag.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/9.
//

import Foundation
import Swallow

extension CommandLineTool {
    public typealias Flag<T> = _CommandLineToolFlag<T>
}

public protocol _CommandLineToolFlagProtocol: PropertyWrapper {
    var _representaton: _CommandLineToolFlagRepresentation { get }
}

public enum _CommandLineToolFlagRepresentation {
    case counter(key: _CommandLineToolOptionKey)
    case boolean(key: _CommandLineToolOptionKey, defaultValue: Bool)
    case optionalBoolean(key: _CommandLineToolOptionKey, inversion: _CommandLineToolFlagInversion)
    case custom
}

@propertyWrapper
public struct _CommandLineToolFlag<WrappedValue>: _CommandLineToolFlagProtocol {
    var _wrappedValue: WrappedValue
    
    public var _representaton: _CommandLineToolFlagRepresentation
  
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            _wrappedValue = newValue
        }
    }

    /// Creates a flag from a non-optional boolean value.
    ///
    /// - parameter key: The option key that would be emitted if necessary as a command argument.
    /// - parameter inversion: The option that converts a flag into `true` / `false` pair. The default value is `nil`, and the flag is only converted into command argument when it's not equal to default value.
    ///
    /// For example:
    ///
    /// ```swift
    /// @Flag(key: .hyphenPrefixed("v")) var verbose: Bool = false
    /// ```
    public init(
        wrappedValue: WrappedValue,
        key: _CommandLineToolOptionKey
    ) where WrappedValue == Bool {
        self._wrappedValue = wrappedValue
        self._representaton = .boolean(
            key: key,
            defaultValue: wrappedValue
        )
    }
    
    /// Creates a flag from an optional boolean value.
    ///
    /// - parameter key: The option key that would be emitted as a command argument.
    /// - parameter inversion: The option that converts a flag into `true` / `false` pair.
    public init(
        wrappedValue: WrappedValue,
        key: _CommandLineToolOptionKey,
        inversion: _CommandLineToolFlagInversion
    ) where WrappedValue == Bool? {
        self._wrappedValue = wrappedValue
        self._representaton = .optionalBoolean(
            key: key,
            inversion: inversion
        )
    }
    
    /// Creates a counter flag from an integer value.
    /// - parameter key: The option key that would be emitted if necessary as a command argument.
    public init(
        wrappedValue: WrappedValue = 0,
        key: _CommandLineToolOptionKey
    ) where WrappedValue == Int {
        self._wrappedValue = wrappedValue
        self._representaton = .counter(key: key)
    }
    
    /// Creates a custom flag from any `OptionKeyConvertible`.
    public init(wrappedValue: WrappedValue) where WrappedValue : CLT.OptionKeyConvertible {
        self._wrappedValue = wrappedValue
        self._representaton = .custom
    }
    
    /// Creates an array of custom flags from any `OptionKeyConvertible`.
    public init<T>(wrappedValue: [T]) where WrappedValue == [T], T : CLT.OptionKeyConvertible {
        self._wrappedValue = wrappedValue
        self._representaton = .custom
    }
    
    /// Creates an array of custom flags from any `OptionKeyConvertible`.
    public init<T>(wrappedValue: [T]?) where WrappedValue == [T]?, T : CLT.OptionKeyConvertible {
        self._wrappedValue = wrappedValue
        self._representaton = .custom
    }
    
    @available(*, unavailable, message: "@Flag only accepts `Bool`, `Int` or any custom types that conforms to `CLT.OptionKeyConvertible`.")
    @_disfavoredOverload
    public init(
        wrappedValue: WrappedValue,
        key: _CommandLineToolOptionKey,
        inversion: _CommandLineToolFlagInversion? = nil
    ) {
        fatalError(.unavailable)
    }
}

/// The option for converting a flag into `true` / `false` pair.
public enum _CommandLineToolFlagInversion: Hashable, Sendable {
    /// Emit `--no-<name>` when the value is `false`.
    case prefixedNo
    /// Emit `--enable-<name>` when `true` and `--disable-<name>` when `false`.
    case prefixedEnableDisable
    
    func argument(_ key: _CommandLineToolOptionKey, value: Bool) -> String {
        let insertionText = switch self {
            case .prefixedNo:
                value ? nil : "no"
            case .prefixedEnableDisable:
                value ? "enable" : "disable"
        }
        
        var argument = key.argumentValue
        guard let insertionText else { return argument }
        
        switch key {
            case .doubleHyphenPrefixed:
                argument.insert(
                    contentsOf: "\(insertionText)-",
                    at: argument.index(atDistance: /* -- */ 2)
                )
            case .hyphenPrefixed:
                argument.insert(
                    contentsOf: "\(insertionText)-",
                    at: argument.index(atDistance: /* - */ 1)
                )
            default:
                break
        }
        return argument
    }
}

/*
 /// The name of the flag as it will be passed in the actual command being invoked.
 var key: _CommandLineToolOptionKey? { get }
 
 /// The options for converting a flag into `true` and `false` pair that would be pass in the actual command being invoked.
 ///
 /// If this value is set, whether it's `true` or `false`, it would always be emitted as a command lint tool argument.
 var inversion: _CommandLineToolFlagInversion? { get }
 
 /// The default value of the flag.
 ///
 /// If the flag is a non-optional boolean value, this value will be used to check if it is the default value. The flag will only be emitted as CLT argument if it's not the default value.
 ///
 /// For example, in the example below, `-v` is generated only when `verbose == true`.
 ///
 /// Since the `verbose` flag does not have a inversion representation, `defaultValue` would be useful to determine whether this flag should be emitted or not.
 ///
 /// ```swift
 /// @Flag(key: .hyphenPrefixed("v")) var verbose: Bool = false
 /// ```
 var _defaultValue: WrappedValue { get }
 */
