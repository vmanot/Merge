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
    /// The representation of the `_CommandLineToolFlag`.
    ///
    /// This must aligned with the `WrappedValue`, for example: `.counter(key:)` assumes `WrappedValue` is `Int`, etc.
    var _representaton: _CommandLineToolFlagRepresentation { get }
}

/// The representation of a command line tool flag that controls how to convert it into command argument.
public enum _CommandLineToolFlagRepresentation {
    /// A counter flag whose value is derived from how many times the option key appears in the command line.
    ///
    /// - Parameter key: The name of the flag as it will be passed in the actual command being invoked.
    case counter(key: _CommandLineToolOptionKey)
    
    /// A non-optional Boolean flag that is only emitted when its value differs from the default.
    ///
    /// - Parameters:
    ///   - key: The name of the flag as it will be passed in the actual command being invoked.
    ///   - defaultValue: The default value of the flag used to determine whether the flag should be emitted.
    case boolean(key: _CommandLineToolOptionKey, defaultValue: Bool)
    
    /// An optional Boolean flag that is always emitted and encoded using an inversion strategy.
    ///
    /// - Parameters:
    ///   - key: The name of the flag as it will be passed in the actual command being invoked.
    ///   - inversion: The options for converting a flag into a `true` / `false` pair that will be passed in the actual command being invoked.
    case optionalBoolean(key: _CommandLineToolOptionKey, inversion: _CommandLineToolFlagInversion)
    
    /// A flag uses custom data type that conforms to `CLT.OptionKeyConvertible`.
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
    
    package func argument(_ key: _CommandLineToolOptionKey, value: Bool) -> String {
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
