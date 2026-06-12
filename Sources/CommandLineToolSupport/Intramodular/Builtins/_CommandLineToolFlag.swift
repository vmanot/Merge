//
// Copyright (c) Vatsal Manot
//


import Foundation
import Swallow

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineTool {
    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public typealias Flag<T: Equatable> = _CommandLineToolFlag<T>
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol _CommandLineToolFlagProtocol: PropertyWrapper, CommandLineToolInvocationSummary.InvocationSummaryValue {
    /// The representation of the `_CommandLineToolFlag`.
    ///
    /// This must aligned with the `WrappedValue`, for example: `.counter(key:)` assumes `WrappedValue` is `Int`, etc.
    var _representation: _CommandLineToolFlagRepresentation { get }

    /// Positional hint for where this flag should appear in the invocation.
    var defaultPosition: _CommandLineToolArgumentPosition { get }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _CommandLineToolFlagProtocol {
    @available(*, deprecated, renamed: "_representation")
    public var _representaton: _CommandLineToolFlagRepresentation {
        _representation
    }

    /// Positional hint for where this flag should appear in the invocation.
    public var placement: CommandLineToolArgumentPlacement {
        defaultPosition
    }
}

/// The representation of a command line tool flag that controls how to convert it into command argument.
public enum _CommandLineToolFlagRepresentation {
    /// A counter flag whose value is derived from how many times the option key appears in the command line.
    ///
    /// - Parameter key: The name of the flag as it will be passed in the actual command being invoked.
    case counter(conversion: _CommandLineToolOptionKeyConversion?, name: String)

    /// A non-optional Boolean flag that is only emitted when its value differs from the default.
    ///
    /// - Parameters:
    ///   - key: The name of the flag as it will be passed in the actual command being invoked.
    ///   - defaultValue: The default value of the flag used to determine whether the flag should be emitted.
    case boolean(conversion: _CommandLineToolOptionKeyConversion?, name: String, defaultValue: Bool)

    /// An optional Boolean flag that is always emitted and encoded using an inversion strategy.
    ///
    /// - Parameters:
    ///   - key: The name of the flag as it will be passed in the actual command being invoked.
    ///   - inversion: The options for converting a flag into a `true` / `false` pair that will be passed in the actual command being invoked.
    case optionalBoolean(conversion: _CommandLineToolOptionKeyConversion?, name: String, inversion: _CommandLineToolFlagInversion)

    /// A flag uses custom data type that conforms to `CLT.OptionKeyConvertible`.
    case custom

    package var inversion: _CommandLineToolFlagInversion? {
        if case .optionalBoolean(_, _, let inversion) = self {
            return inversion
        }
        return nil
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@propertyWrapper
public struct _CommandLineToolFlag<WrappedValue: Equatable>: _CommandLineToolFlagProtocol {
    var _wrappedValue: WrappedValue

    public var _representation: _CommandLineToolFlagRepresentation
    @available(*, deprecated, renamed: "_representation")
    public var _representaton: _CommandLineToolFlagRepresentation {
        get {
            _representation
        } set {
            _representation = newValue
        }
    }
    public var defaultPosition: _CommandLineToolArgumentPosition

    /// Positional hint for where this flag should appear in the invocation.
    public var placement: CommandLineToolArgumentPlacement {
        get {
            defaultPosition
        } set {
            defaultPosition = newValue
        }
    }

    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            _wrappedValue = newValue
        }
    }

    public var projectedValue: _CommandLineToolFlag<WrappedValue> {
        self
    }

    public func resolve(
        in context: _CommandLineToolResolutionContext
    ) throws -> _AnyResolvedCommandLineToolInvocationArgument {
        switch _representation {
            case .custom:
                _ResolvedCommandLineToolDescription.CustomFlag(
                    id: context.resolvingID,
                    defaultPosition: defaultPosition,
                    value: wrappedValue,
                    valueType: type(of: wrappedValue),
                ).erasedToAnyResolvedCommandLineToolInvocationArgument()
            case .counter(let conversion, let name):
                _ResolvedCommandLineToolDescription.CounterFlag(
                    id: context.resolvingID,
                    defaultPosition: defaultPosition,
                    conversion: conversion ?? context.implicitKeyConversion(for: name),
                    name: name,
                    count: _expectWrappedValue(Int.self, for: _representation),
                    isClustered: name.count == 1
                ).erasedToAnyResolvedCommandLineToolInvocationArgument()
            case .boolean(let conversion, let name, let defaultValue):
                _ResolvedCommandLineToolDescription.BooleanFlag(
                    id: context.resolvingID,
                    defaultPosition: defaultPosition,
                    conversion: conversion ?? context.implicitKeyConversion(for: name),
                    name: name,
                    inversion: nil, // only be able to switch to another state (true / false)
                    defaultBooleanValue: defaultValue,
                    isOn: _expectWrappedValue(Bool.self, for: _representation)
                ).erasedToAnyResolvedCommandLineToolInvocationArgument()
            case .optionalBoolean(let conversion, let name, let inversion):
                _ResolvedCommandLineToolDescription.BooleanFlag(
                    id: context.resolvingID,
                    defaultPosition: defaultPosition,
                    conversion: conversion ?? context.implicitKeyConversion(for: name),
                    name: name,
                    inversion: inversion,
                    defaultBooleanValue: nil,
                    isOn: _expectWrappedValue(Optional<Bool>.self, for: _representation)
                ).erasedToAnyResolvedCommandLineToolInvocationArgument()
        }
    }

    private func _expectWrappedValue<T>(
        _ type: T.Type,
        for representation: _CommandLineToolFlagRepresentation
    ) -> T {
        guard let value = wrappedValue as? T else {
            preconditionFailure("Flag representation \(representation) expects \(T.self), but \(WrappedValue.self) was provided.")
        }

        return value
    }

}

/// The option for converting a flag into `true` / `false` pair.
public enum _CommandLineToolFlagInversion: Hashable, Sendable {
    /// Emit `--no-<name>` when the value is `false`.
    case prefixedNo
    /// Emit `--enable-<name>` when `true` and `--disable-<name>` when `false`.
    case prefixedEnableDisable

    package func argument(
        conversion: _CommandLineToolOptionKeyConversion,
        name: String,
        value: Bool
    ) -> String {
        let insertionText = switch self {
            case .prefixedNo:
                value ? nil : "no"
            case .prefixedEnableDisable:
                value ? "enable" : "disable"
        }

        let base = conversion.argumentKey(for: name)
        guard let insertionText else {
            return base
        }

        return conversion.prefix + insertionText + "-" + name
    }
}
