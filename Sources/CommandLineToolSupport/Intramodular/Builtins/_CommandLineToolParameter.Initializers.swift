//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation

extension _CommandLineToolParameter {
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

    @_disfavoredOverload
    public init(
        wrappedValue: WrappedValue
    ) {
        self.init(
            wrappedValue: wrappedValue,
            name: nil
        )
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
