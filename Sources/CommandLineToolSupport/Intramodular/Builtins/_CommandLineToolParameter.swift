//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public protocol _CommandLineToolParameterProtocol: PropertyWrapper {
    /// The name of the parameter as it will be passed in the actual command being invoked.
    var name: _CommandLineToolParameterName { get }
}

@propertyWrapper
public struct _CommandLineToolParameter<WrappedValue>: _CommandLineToolParameterProtocol {
    var _wrappedValue: WrappedValue

    public var name: _CommandLineToolParameterName
    
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            _wrappedValue = newValue
        }
    }
    
    public init(wrappedValue: WrappedValue, name: _CommandLineToolParameterName) {
        self._wrappedValue = wrappedValue
        self.name = name
    }
}

public enum _CommandLineToolParameterName: Hashable, Sendable {
    /// A parameter name prefixed with one hyphen, for example: `-o`, `-output`, etc.
    case hyphenPrefixed(String)
    /// A parameter name prefixed with two hyphens, for example: `--output`, etc.
    case doubleHyphenPrefixed(String)
}

extension CommandLineTool {
    public typealias Parameter<T> = _CommandLineToolParameter<T>
}
