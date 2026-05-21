//
// Copyright (c) Vatsal Manot
//

import Foundation

extension _CommandLineToolParameter {
    fileprivate init(
        _initializing wrappedValue: WrappedValue,
        name: String?,
        conversion: _CommandLineToolOptionKeyConversion? = nil,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy? = nil,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) {
        self.storage = Storage(wrappedValue: wrappedValue)
        self.name = name
        self.optionKeyConversion = conversion
        self.keyValueSeparator = separator
        self.multiValueEncodingStrategy = encoding
        self.defaultPosition = defaultPosition
    }

    @_disfavoredOverload
    public init(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) {
        self.init(
            _initializing: wrappedValue,
            name: name,
            separator: separator,
            defaultPosition: defaultPosition
        )
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

extension _CommandLineToolParameter where WrappedValue: CLT.ArgumentValueConvertible {
    public init(
        wrappedValue: WrappedValue
    ) {
        self.init(
            wrappedValue: wrappedValue,
            name: nil
        )
    }

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

    public init(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) {
        self.init(
            _initializing: wrappedValue,
            name: name,
            conversion: conversion,
            separator: separator,
            defaultPosition: defaultPosition
        )
    }
}

extension _CommandLineToolParameter {
    public init<T>(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == [T]?, T: CLT.ArgumentValueConvertible {
        self.init(
            wrappedValue: wrappedValue,
            name: name,
            separator: separator,
            encoding: encoding,
            defaultPosition: placement
        )
    }

    public init<T>(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == [T]?, T: CLT.ArgumentValueConvertible {
        self.init(
            _initializing: wrappedValue,
            name: name,
            separator: separator,
            encoding: encoding,
            defaultPosition: defaultPosition
        )
    }

    public init<T>(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == [T]?, T: CLT.ArgumentValueConvertible {
        self.init(
            wrappedValue: wrappedValue,
            conversion: conversion,
            name: name,
            separator: separator,
            encoding: encoding,
            defaultPosition: placement
        )
    }

    public init<T>(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == [T]?, T: CLT.ArgumentValueConvertible {
        self.init(
            _initializing: wrappedValue,
            name: name,
            conversion: conversion,
            separator: separator,
            encoding: encoding,
            defaultPosition: defaultPosition
        )
    }

    public init<T>(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == [T], T: CLT.ArgumentValueConvertible {
        self.init(
            wrappedValue: wrappedValue,
            name: name,
            separator: separator,
            encoding: encoding,
            defaultPosition: placement
        )
    }

    public init<T>(
        wrappedValue: WrappedValue,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == [T], T: CLT.ArgumentValueConvertible {
        self.init(
            _initializing: wrappedValue,
            name: name,
            separator: separator,
            encoding: encoding,
            defaultPosition: defaultPosition
        )
    }

    public init<T>(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == [T], T: CLT.ArgumentValueConvertible {
        self.init(
            wrappedValue: wrappedValue,
            conversion: conversion,
            name: name,
            separator: separator,
            encoding: encoding,
            defaultPosition: placement
        )
    }

    public init<T>(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion,
        name: String?,
        separator: _CommandLineToolParameterKeyValueSeparator = .space,
        encoding: MultiValueParameterEncodingStrategy = .singleValue,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == [T], T: CLT.ArgumentValueConvertible {
        self.init(
            _initializing: wrappedValue,
            name: name,
            conversion: conversion,
            separator: separator,
            encoding: encoding,
            defaultPosition: defaultPosition
        )
    }
}
