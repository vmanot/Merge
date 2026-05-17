#if os(macOS)
//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension CommandLineTool {
    public typealias Parameter<T> = _CommandLineToolParameter<T>
}

public protocol _CommandLineToolParameterProtocol: PropertyWrapper, CommandLineToolInvocationSummary.InvocationSummaryValue {
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

extension _CommandLineToolParameterProtocol {
    /// Positional hint for where this parameter should appear in the invocation.
    public var placement: CommandLineToolArgumentPlacement {
        defaultPosition
    }
}

@propertyWrapper
public struct _CommandLineToolParameter<WrappedValue>: _CommandLineToolParameterProtocol {
    private final class Storage {
        var wrappedValue: Any?

        init(wrappedValue: Any? = nil) {
            self.wrappedValue = wrappedValue
        }
    }

    private let storage: Storage

    public var name: String?
    public var optionKeyConversion: _CommandLineToolOptionKeyConversion?
    public var keyValueSeparator: _CommandLineToolParameterKeyValueSeparator
    public var multiValueEncodingStrategy: MultiValueParameterEncodingStrategy?
    public var defaultPosition: _CommandLineToolArgumentPosition = .local

    /// Positional hint for where this parameter should appear in the invocation.
    public var placement: CommandLineToolArgumentPlacement {
        get {
            defaultPosition
        } set {
            defaultPosition = newValue
        }
    }

    public var wrappedValue: WrappedValue {
        get {
            if let value = storage.wrappedValue as? WrappedValue {
                return value
            }

            if let value = (Optional<Any>.none as Any) as? WrappedValue {
                return value
            }

            preconditionFailure("Parameter \(WrappedValue.self) was read before being initialized.")
        } nonmutating set {
            storage.wrappedValue = newValue
        }
    }

    public var projectedValue: _CommandLineToolParameter<WrappedValue> {
        self
    }

    public func resolve(
        in context: _CommandLineToolResolutionContext
    ) throws -> _AnyResolvedCommandLineToolInvocationArgument {
        let wrappedValue = self.wrappedValue

        return if let name {
            _ResolvedCommandLineToolDescription.Option(
                id: context.resolvingID,
                defaultPosition: defaultPosition,
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
                defaultPosition: defaultPosition,
                value: wrappedValue,
                valueType: type(of: wrappedValue)
            ).erasedToAnyResolvedCommandLineToolInvocationArgument()
        }
    }

    @_disfavoredOverload
    public init() {
        self.storage = Storage()
        self.name = nil
        self.keyValueSeparator = .space
        self.multiValueEncodingStrategy = nil
        self.defaultPosition = .local
    }

    @_disfavoredOverload
    public init(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) {
        self.storage = Storage(wrappedValue: wrappedValue)
        self.name = name
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = nil
        self.defaultPosition = defaultPosition
    }
}

extension _CommandLineToolParameter where WrappedValue : CLT.ArgumentValueConvertible {
    /// Creates a positional argument from a wrapped value.
    public init(
        wrappedValue: WrappedValue
    ) {
        self.init(
            wrappedValue: wrappedValue,
            name: nil
        )
    }

    /// Creates a property that reads its value from a labeled option or an argument.
    public init(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        placement: CommandLineToolArgumentPlacement
    ) {
        self.init(
            wrappedValue: wrappedValue,
            name: name,
            separator: separator,
            defaultPosition: placement
        )
    }

    /// Creates a property that reads its value from a labeled option or an argument.
    public init(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        placement: CommandLineToolArgumentPlacement
    ) {
        self.init(
            wrappedValue: wrappedValue,
            conversion: conversion,
            name: name,
            separator: separator,
            defaultPosition: placement
        )
    }

    /// Creates a property that reads its value from a labeled option or an argument.
    public init(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) {
        self.init(
            wrappedValue: wrappedValue,
            name: name,
            separator: separator,
            defaultPosition: defaultPosition
        )
        self.optionKeyConversion = conversion
    }
}

extension _CommandLineToolParameter {
    /// Creates an array that reads its value from zero or more labeled options or arguments.
    public init<T>(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == [T]?, T : CLT.ArgumentValueConvertible {
        self.init(
            wrappedValue: wrappedValue,
            name: name,
            separator: separator,
            encoding: encoding,
            defaultPosition: placement
        )
    }

    /// Creates an array that reads its value from zero or more labeled options or arguments.
    public init<T>(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == [T]?, T : CLT.ArgumentValueConvertible {
        self.storage = Storage(wrappedValue: wrappedValue)
        self.name = name
        self.optionKeyConversion = nil
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
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == [T]?, T : CLT.ArgumentValueConvertible {
        self.init(
            wrappedValue: wrappedValue,
            conversion: conversion,
            name: name,
            separator: separator,
            encoding: encoding,
            defaultPosition: placement
        )
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
        self.init(
            wrappedValue: wrappedValue,
            name: name,
            separator: separator,
            encoding: encoding,
            defaultPosition: defaultPosition
        )
        self.optionKeyConversion = conversion
        self.multiValueEncodingStrategy = encoding
    }
}

extension _CommandLineToolParameter {
    /// Creates an array that reads its value from zero or more labeled options or arguments.
    public init<T>(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == [T], T : CLT.ArgumentValueConvertible {
        self.init(
            wrappedValue: wrappedValue,
            name: name,
            separator: separator,
            encoding: encoding,
            defaultPosition: placement
        )
    }

    /// Creates an array that reads its value from zero or more labeled options or arguments.
    public init<T>(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == [T], T : CLT.ArgumentValueConvertible {
        self.storage = Storage(wrappedValue: wrappedValue)
        self.name = name
        self.optionKeyConversion = nil
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
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == [T], T : CLT.ArgumentValueConvertible {
        self.init(
            wrappedValue: wrappedValue,
            conversion: conversion,
            name: name,
            separator: separator,
            encoding: encoding,
            defaultPosition: placement
        )
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
        self.init(
            wrappedValue: wrappedValue,
            name: name,
            separator: separator,
            encoding: encoding,
            defaultPosition: defaultPosition
        )
        self.optionKeyConversion = conversion
    }
}

#endif
