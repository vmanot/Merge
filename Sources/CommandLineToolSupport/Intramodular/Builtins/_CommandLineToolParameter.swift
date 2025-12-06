//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public protocol _CommandLineToolParameterProtocol: PropertyWrapper {
    /// The name of the parameter as it will be passed in the actual command being invoked.
    var name: _CommandLineToolParameterName { get }
    
    /// Defines how the parameter’s value is joined with its key when constructing the final command-line invocation.
    ///
    /// For example, `--output <path>`, or `--output=value`.
    var valueStyle: _CommandLineToolParameterValueStyle { get }
}

@propertyWrapper
public struct _CommandLineToolParameter<WrappedValue>: _CommandLineToolParameterProtocol {
    var _wrappedValue: WrappedValue

    public var name: _CommandLineToolParameterName
    public var valueStyle: _CommandLineToolParameterValueStyle
    
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            _wrappedValue = newValue
        }
    }
    
    public init(
        wrappedValue: WrappedValue,
        name: _CommandLineToolParameterName,
        valueStyle: _CommandLineToolParameterValueStyle = .space
    ) {
        self._wrappedValue = wrappedValue
        self.name = name
        self.valueStyle = valueStyle
    }
}

public enum _CommandLineToolParameterName: Hashable, Sendable {
    /// A parameter name prefixed with one hyphen, for example: `-o`, `-output`, etc.
    case hyphenPrefixed(String)
    /// A parameter name prefixed with two hyphens, for example: `--output`, etc.
    case doubleHyphenPrefixed(String)
}

public enum _CommandLineToolParameterValueStyle: String, Hashable, Sendable {
    /// A value style that use a space character as separator between key and value.
    ///
    /// For example: `-o <path>`
    case space = " "
    /// A value style that use an equal character as separator between key and value.
    ///
    /// For example: `-cxx-interoperability-mode=default` for `xcrun swiftc`
    case equal = "="
    
    /// A value style that uses a plus character as separator between key and value.
    ///
    /// For example: `-framework+UIKit` for legacy `Id` CLT.
    ///
    /// - warning: This is a legacy value style and may not support in the mordern toolchain.
    case plus = "+"
    
    /// A value style that uses a slash character as separator between key and value.
    ///
    /// Commonly used in some Windows CLIs, for example: `/out:program.exe`.
    case slash = "/"
}

extension CommandLineTool {
    public typealias Parameter<T> = _CommandLineToolParameter<T>
}
