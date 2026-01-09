//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension CommandLineTool {
    public typealias Parameter<T> = _CommandLineToolParameter<T>
}

public protocol _CommandLineToolParameterProtocol: PropertyWrapper, InvocationSummaryValue {
    /// The name of the parameter as it will be passed in the actual command being invoked.
    var name: String? { get }
    
    var optionKeyConversion: _CommandLineToolOptionKeyConversion? { get }
    
    /// Defines how the parameter’s value is joined with its key when constructing the final command-line invocation.
    ///
    /// For example, `--output <path>`, or `--output=value`.
    var keyValueSeparator: _CommandLineToolParameterKeyValueSeparator { get }
    
    /// Defines how multi-value parameter is converted into argument(s) that would be passed in the actual command being invoked.
    var multiValueEncodingStrategy: MultiValueParameterEncodingStrategy? { get }
    
    /// Positional hint for where this parameter should appear in the invocation.
    var defaultPosition: _CommandLineToolArgumentPosition { get }
}

@propertyWrapper
public struct _CommandLineToolParameter<WrappedValue>: _CommandLineToolParameterProtocol {
    var _wrappedValue: WrappedValue

    public var name: String?
    public var optionKeyConversion: _CommandLineToolOptionKeyConversion?
    public var keyValueSeparator: _CommandLineToolParameterKeyValueSeparator
    public var multiValueEncodingStrategy: MultiValueParameterEncodingStrategy?
    public var defaultPosition: _CommandLineToolArgumentPosition = .local
    
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            _wrappedValue = newValue
        }
    }
    
    public var projectedValue: _CommandLineToolParameter<WrappedValue> {
        self
    }
    
    public func resolve(
        in context: _CommandLineToolResolutionContext
    ) throws -> _AnyResolvedCommandLineToolInvocationArgument {
        if let name {
            _ResolvedCommandLineToolDescription.Option(
                id: context.resolvingID,
                conversion: optionKeyConversion ?? context.implicitKeyConversion(for: name),
                name: name,
                separator: keyValueSeparator,
                multiValueEncoding: multiValueEncodingStrategy,
                value: wrappedValue,
                valueType: type(of: wrappedValue)
            ).erasedToAnyResolvedCommandLineToolInvocationArgument()
        } else {
            _ResolvedCommandLineToolDescription.Argument(
                id: context.resolvingID,
                value: wrappedValue,
                valueType: type(of: wrappedValue)
            ).erasedToAnyResolvedCommandLineToolInvocationArgument()
        }
    }
    
    @available(*, unavailable, message: "This parameter will be ignored. Make sure `WrappedValue` conforms to `CLT.ArgumentValueConvertible`.")
    @_disfavoredOverload
    public init(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) {
        self._wrappedValue = wrappedValue
        self.name = name
        self.keyValueSeparator = separator
        self.defaultPosition = defaultPosition
    }
}

extension _CommandLineToolParameter where WrappedValue : CLT.ArgumentValueConvertible {
    /// Creates a property that reads its value from a labeled option or an argument.
    public init(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) {
        self._wrappedValue = wrappedValue
        self.name = name
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = nil
        self.defaultPosition = defaultPosition
    }
    
    /// Creates a property that reads its value from a labeled option or an argument.
    public init(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) {
        self._wrappedValue = wrappedValue
        self.name = name
        self.optionKeyConversion = conversion
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = nil
        self.defaultPosition = defaultPosition
    }
}

extension _CommandLineToolParameter {
    /// Creates an array that reads its value from zero or more labeled options or arguments.
    public init<T>(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == [T]?, T : CLT.ArgumentValueConvertible {
        self._wrappedValue = wrappedValue
        self.name = name
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = encoding
        self.defaultPosition = defaultPosition
    }
    
    /// Creates an array that reads its value from zero or more labeled options or arguments.
    public init<T>(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == [T]?, T : CLT.ArgumentValueConvertible {
        self._wrappedValue = wrappedValue
        self.name = name
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = encoding
        self.defaultPosition = defaultPosition
    }
}

extension _CommandLineToolParameter {
    /// Creates an array that reads its value from zero or more labeled options or arguments.
    public init<T>(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == [T], T : CLT.ArgumentValueConvertible {
        self._wrappedValue = wrappedValue
        self.name = name
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = encoding
        self.defaultPosition = defaultPosition
    }

    /// Creates an array that reads its value from zero or more labeled options or arguments.
    public init<T>(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == [T], T : CLT.ArgumentValueConvertible {
        self._wrappedValue = wrappedValue
        self.name = name
        self.optionKeyConversion = conversion
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = encoding
        self.defaultPosition = defaultPosition
    }
}
