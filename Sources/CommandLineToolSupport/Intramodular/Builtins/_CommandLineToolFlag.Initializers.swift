//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swallow

extension _CommandLineToolFlag {
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
        self._wrappedValue = wrappedValue
        self._representaton = .boolean(
            conversion: conversion,
            name: name,
            defaultValue: wrappedValue
        )
        self.defaultPosition = defaultPosition
    }

    public init(
        wrappedValue: WrappedValue,
        defaultValue: Bool,
        conversion: _CommandLineToolOptionKeyConversion? = nil,
        name: String,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == Bool {
        self._wrappedValue = wrappedValue
        self._representaton = .boolean(
            conversion: conversion,
            name: name,
            defaultValue: defaultValue
        )
        self.defaultPosition = defaultPosition
    }

    /// Creates a flag from an optional boolean value.
    ///
    /// - parameter key: The option key that would be emitted as a command argument.
    /// - parameter inversion: The option that converts a flag into `true` / `false` pair.
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
        self._wrappedValue = wrappedValue
        self._representaton = .optionalBoolean(
            conversion: conversion,
            name: name,
            inversion: inversion
        )
        self.defaultPosition = defaultPosition
    }

    /// Creates a counter flag from an integer value.
    /// - parameter key: The option key that would be emitted if necessary as a command argument.
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
        self._wrappedValue = wrappedValue
        self._representaton = .counter(
            conversion: conversion,
            name: name
        )
        self.defaultPosition = defaultPosition
    }

    /// Creates a custom flag from any `OptionKeyConvertible`.
    public init(
        wrappedValue: WrappedValue,
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue : CLT.OptionKeyConvertible {
        self.init(
            wrappedValue: wrappedValue,
            defaultPosition: placement
        )
    }

    /// Creates a custom flag from any `OptionKeyConvertible`.
    public init(
        wrappedValue: WrappedValue,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue : CLT.OptionKeyConvertible {
        self._wrappedValue = wrappedValue
        self._representaton = .custom
        self.defaultPosition = defaultPosition
    }

    /// Creates an array of custom flags from any `OptionKeyConvertible`.
    public init<T>(
        wrappedValue: [T],
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == [T], T : CLT.OptionKeyConvertible {
        self.init(
            wrappedValue: wrappedValue,
            defaultPosition: placement
        )
    }

    /// Creates an array of custom flags from any `OptionKeyConvertible`.
    public init<T>(
        wrappedValue: [T],
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == [T], T : CLT.OptionKeyConvertible {
        self._wrappedValue = wrappedValue
        self._representaton = .custom
        self.defaultPosition = defaultPosition
    }

    /// Creates an array of custom flags from any `OptionKeyConvertible`.
    public init<T>(
        wrappedValue: [T]?,
        placement: CommandLineToolArgumentPlacement
    ) where WrappedValue == [T]?, T : CLT.OptionKeyConvertible {
        self.init(
            wrappedValue: wrappedValue,
            defaultPosition: placement
        )
    }

    /// Creates an array of custom flags from any `OptionKeyConvertible`.
    public init<T>(
        wrappedValue: [T]?,
        defaultPosition: _CommandLineToolArgumentPosition = .local
    ) where WrappedValue == [T]?, T : CLT.OptionKeyConvertible {
        self._wrappedValue = wrappedValue
        self._representaton = .custom
        self.defaultPosition = defaultPosition
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

#endif
