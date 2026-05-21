//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension _CommandLineToolFlag {
    fileprivate init(
        _initializing wrappedValue: WrappedValue,
        representation: _CommandLineToolFlagRepresentation,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) {
        self._wrappedValue = wrappedValue
        self._representation = representation
        self.defaultPosition = defaultPosition
    }

    public init(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion? = nil,
        name: String,
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == Bool {
        self.init(
            wrappedValue: wrappedValue,
            conversion: conversion,
            name: name,
            defaultPosition: placement
        )
    }

    public init(
        wrappedValue: WrappedValue,
        defaultValue: Bool,
        conversion: _CommandLineToolOptionKeyConversion? = nil,
        name: String,
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == Bool {
        self.init(
            wrappedValue: wrappedValue,
            defaultValue: defaultValue,
            conversion: conversion,
            name: name,
            defaultPosition: placement
        )
    }

    public init(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion? = nil,
        name: String,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == Bool {
        self.init(
            _initializing: wrappedValue,
            representation: .boolean(
                conversion: conversion,
                name: name,
                defaultValue: wrappedValue
            ),
            defaultPosition: defaultPosition
        )
    }

    public init(
        wrappedValue: WrappedValue,
        defaultValue: Bool,
        conversion: _CommandLineToolOptionKeyConversion? = nil,
        name: String,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == Bool {
        self.init(
            _initializing: wrappedValue,
            representation: .boolean(
                conversion: conversion,
                name: name,
                defaultValue: defaultValue
            ),
            defaultPosition: defaultPosition
        )
    }

    public init(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion? = nil,
        name: String,
        inversion: _CommandLineToolFlagInversion,
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == Bool? {
        self.init(
            wrappedValue: wrappedValue,
            conversion: conversion,
            name: name,
            inversion: inversion,
            defaultPosition: placement
        )
    }

    public init(
        wrappedValue: WrappedValue,
        conversion: _CommandLineToolOptionKeyConversion? = nil,
        name: String,
        inversion: _CommandLineToolFlagInversion,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == Bool? {
        self.init(
            _initializing: wrappedValue,
            representation: .optionalBoolean(
                conversion: conversion,
                name: name,
                inversion: inversion
            ),
            defaultPosition: defaultPosition
        )
    }

    public init(
        wrappedValue: WrappedValue = 0,
        conversion: _CommandLineToolOptionKeyConversion? = nil,
        name: String,
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == Int {
        self.init(
            wrappedValue: wrappedValue,
            conversion: conversion,
            name: name,
            defaultPosition: placement
        )
    }

    public init(
        wrappedValue: WrappedValue = 0,
        conversion: _CommandLineToolOptionKeyConversion? = nil,
        name: String,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == Int {
        self.init(
            _initializing: wrappedValue,
            representation: .counter(
                conversion: conversion,
                name: name
            ),
            defaultPosition: defaultPosition
        )
    }

    public init(
        wrappedValue: WrappedValue,
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue: CLT.OptionKeyConvertible {
        self.init(
            wrappedValue: wrappedValue,
            defaultPosition: placement
        )
    }

    public init(
        wrappedValue: WrappedValue,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue: CLT.OptionKeyConvertible {
        self.init(
            _initializing: wrappedValue,
            representation: .custom,
            defaultPosition: defaultPosition
        )
    }

    public init<T>(
        wrappedValue: [T],
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == [T], T: CLT.OptionKeyConvertible {
        self.init(
            wrappedValue: wrappedValue,
            defaultPosition: placement
        )
    }

    public init<T>(
        wrappedValue: [T],
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == [T], T: CLT.OptionKeyConvertible {
        self.init(
            _initializing: wrappedValue,
            representation: .custom,
            defaultPosition: defaultPosition
        )
    }

    public init<T>(
        wrappedValue: [T]?,
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == [T]?, T: CLT.OptionKeyConvertible {
        self.init(
            wrappedValue: wrappedValue,
            defaultPosition: placement
        )
    }

    public init<T>(
        wrappedValue: [T]?,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == [T]?, T: CLT.OptionKeyConvertible {
        self.init(
            _initializing: wrappedValue,
            representation: .custom,
            defaultPosition: defaultPosition
        )
    }

    @available(*, unavailable, message: "@Flag only accepts `Bool`, `Int` or any custom types that conforms to `CLT.OptionKeyConvertible`.")
    @_disfavoredOverload
    public init(
        wrappedValue: WrappedValue,
        key: _CommandLineToolOptionKeyConversion,
        inversion: _CommandLineToolFlagInversion? = nil
    ) {
        fatalError(.unavailable)
    }
}
