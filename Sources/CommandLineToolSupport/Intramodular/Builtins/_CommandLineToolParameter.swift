//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension CommandLineTool {
    public typealias Parameter<T> = _CommandLineToolParameter<T>
}

public protocol _CommandLineToolParameterProtocol: PropertyWrapper {
    /// The name of the parameter as it will be passed in the actual command being invoked.
    var key: _CommandLineToolParameterOptionKey? { get }
    
    /// Defines how the parameter’s value is joined with its key when constructing the final command-line invocation.
    ///
    /// For example, `--output <path>`, or `--output=value`.
    var keyValueSeparator: _CommandLineToolParameterKeyValueSeparator { get }
    
    /// Defines how multi-value parameter is converted into argument(s) that would be passed in the actual command being invoked.
    var multiValueEncodingStrategy: MultiValueParameterEncodingStrategy? { get }
}

@propertyWrapper
public struct _CommandLineToolParameter<WrappedValue>: _CommandLineToolParameterProtocol {
    var _wrappedValue: WrappedValue

    public var key: _CommandLineToolParameterOptionKey?
    public var keyValueSeparator: _CommandLineToolParameterKeyValueSeparator
    public var multiValueEncodingStrategy: MultiValueParameterEncodingStrategy?
    
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            _wrappedValue = newValue
        }
    }
    
    public init(
        wrappedValue: WrappedValue,
        key: _CommandLineToolParameterOptionKey?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space
    ) where WrappedValue : CLT.ArgumentValueConvertible {
        self._wrappedValue = wrappedValue
        self.key = key
        self.keyValueSeparator = separator
    }
    
    public init<T>(
        wrappedValue: WrappedValue,
        key: _CommandLineToolParameterOptionKey?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue
    ) where WrappedValue == [T]?, T : CLT.ArgumentValueConvertible {
        self._wrappedValue = wrappedValue
        self.key = key
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = encoding
    }
    
    public init<T>(
        wrappedValue: WrappedValue,
        key: _CommandLineToolParameterOptionKey?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue
    ) where WrappedValue == [T], T : CLT.ArgumentValueConvertible {
        self._wrappedValue = wrappedValue
        self.key = key
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = encoding
    }
    
    @available(*, deprecated, message: "This parameter will be ignored. Make sure `WrappedValue` conforms to `CLT.ArgumentValueConvertible`.")
    @_disfavoredOverload
    public init(
        wrappedValue: WrappedValue,
        key: _CommandLineToolParameterOptionKey?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space
    ) {
        self._wrappedValue = wrappedValue
        self.key = key
        self.keyValueSeparator = separator
    }
}

public enum _CommandLineToolParameterOptionKey: CLT.ArgumentValueConvertible, Hashable, Sendable {
    /// A parameter name prefixed with one hyphen, for example: `-o`, `-output`, etc.
    case hyphenPrefixed(String)
    /// A parameter name prefixed with two hyphens, for example: `--output`, etc.
    case doubleHyphenPrefixed(String)
    /// A parameter name prefixed with a slash, for example: `/out`, etc.
    ///
    /// Commonly used in some Windows CLIs.
    case slashPrefixed(String)
    
    public var argumentValue: String {
        switch self {
            case .doubleHyphenPrefixed(let name):
                "--\(name)"
            case .hyphenPrefixed(let name):
                "-\(name)"
            case .slashPrefixed(let name):
                "/\(name)"
        }
    }
}

public enum _CommandLineToolParameterKeyValueSeparator: String, Hashable, Sendable {
    /// Uses a space character as separator between key and value.
    ///
    /// For example: `-o <path>`
    case space = " "
    /// Uses an equal character as separator between key and value.
    ///
    /// For example: `-cxx-interoperability-mode=default` for `xcrun swiftc`
    case equal = "="
    
    /// Uses a plus character as separator between key and value.
    ///
    /// For example: `-framework+UIKit` for legacy `Id` CLT.
    ///
    /// - warning: This is a legacy value style and may not support in the mordern toolchain.
    case plus = "+"
    
    /// Uses a colon character as separator between key and value.
    ///
    /// Commonly used in some Windows CLIs, for example: `/out:program.exe`.
    case colon = ":"
}

/// Describes how multi-value parameters are encoded on the command line.
public enum MultiValueParameterEncodingStrategy {
    /// Each parameter value is attached to an independent key.
    ///
    /// For example: `-Xcc -fmodule-map-file=foo.modulemap -Xcc -fmodules` for `xcrun_swiftc`
    case singleValue
    
    /// Multiple values are attached to the same option key and joined with a whitespace.
    ///
    /// For example: `--platform ios macOS watchOS` for `crowbar-tool`
    case spaceSeparated
}
