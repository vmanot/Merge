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
    var name: String? { get }
    
    var optionKeyConversion: _CommandLineToolOptionKeyConversion? { get }
    
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

    public var name: String?
    public var optionKeyConversion: _CommandLineToolOptionKeyConversion?
    public var keyValueSeparator: _CommandLineToolParameterKeyValueSeparator
    public var multiValueEncodingStrategy: MultiValueParameterEncodingStrategy?
    
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            _wrappedValue = newValue
        }
    }
    
    @available(*, deprecated, message: "This parameter will be ignored. Make sure `WrappedValue` conforms to `CLT.ArgumentValueConvertible`.")
    @_disfavoredOverload
    public init(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space
    ) {
        self._wrappedValue = wrappedValue
        self.name = name
        self.keyValueSeparator = separator
    }
}

extension _CommandLineToolParameter where WrappedValue : CLT.ArgumentValueConvertible {
    /// Creates a property that reads its value from a labeled option or an argument.
    public init(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space
    ) {
        self._wrappedValue = wrappedValue
        self.name = name
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = nil
    }
    
    /// Creates a property that reads its value from a labeled option or an argument.
    public init(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space
    ) {
        self._wrappedValue = wrappedValue
        self.name = name
        self.optionKeyConversion = conversion
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = nil
    }
}

extension _CommandLineToolParameter {
    /// Creates an array that reads its value from zero or more labeled options or arguments.
    public init<T>(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue
    ) where WrappedValue == [T]?, T : CLT.ArgumentValueConvertible {
        self._wrappedValue = wrappedValue
        self.name = name
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = encoding
    }
    
    /// Creates an array that reads its value from zero or more labeled options or arguments.
    public init<T>(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue
    ) where WrappedValue == [T]?, T : CLT.ArgumentValueConvertible {
        self._wrappedValue = wrappedValue
        self.name = name
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = encoding
    }
}

extension _CommandLineToolParameter {
    /// Creates an array that reads its value from zero or more labeled options or arguments.
    public init<T>(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue
    ) where WrappedValue == [T], T : CLT.ArgumentValueConvertible {
        self._wrappedValue = wrappedValue
        self.name = name
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = encoding
    }

    /// Creates an array that reads its value from zero or more labeled options or arguments.
    public init<T>(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue
    ) where WrappedValue == [T], T : CLT.ArgumentValueConvertible {
        self._wrappedValue = wrappedValue
        self.name = name
        self.optionKeyConversion = conversion
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = encoding
    }
}

