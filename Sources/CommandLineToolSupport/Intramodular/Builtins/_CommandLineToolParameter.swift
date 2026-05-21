//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension CommandLineTool {
    public typealias Argument<T> = _CommandLineToolParameter<T>
    public typealias Option<T> = _CommandLineToolParameter<T>

    @available(*, deprecated, message: "Use @Argument for positional arguments or @Option for keyed options.")
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
    final class Storage {
        var wrappedValue: Any?

        init(wrappedValue: Any? = nil) {
            self.wrappedValue = wrappedValue
        }
    }

    let storage: Storage

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
        if let name {
            return _resolveOption(
                name: name,
                in: context
            )
        } else {
            return _resolvePositionalArgument(in: context)
        }
    }

    private func _resolveOption(
        name: String,
        in context: _CommandLineToolResolutionContext
    ) -> _AnyResolvedCommandLineToolInvocationArgument {
        let wrappedValue = self.wrappedValue

        return _ResolvedCommandLineToolDescription.Option(
            id: context.resolvingID,
            defaultPosition: defaultPosition,
            conversion: optionKeyConversion ?? context.implicitKeyConversion(for: name),
            name: name,
            separator: keyValueSeparator,
            multiValueEncoding: multiValueEncodingStrategy,
            value: wrappedValue,
            valueType: type(of: wrappedValue)
        ).erasedToAnyResolvedCommandLineToolInvocationArgument()
    }

    private func _resolvePositionalArgument(
        in context: _CommandLineToolResolutionContext
    ) -> _AnyResolvedCommandLineToolInvocationArgument {
        let wrappedValue = self.wrappedValue

        return _ResolvedCommandLineToolDescription.Argument(
            id: context.resolvingID,
            defaultPosition: defaultPosition,
            value: wrappedValue,
            valueType: type(of: wrappedValue)
        ).erasedToAnyResolvedCommandLineToolInvocationArgument()
    }

    @_disfavoredOverload
    public init() {
        self.storage = Storage()
        self.name = nil
        self.keyValueSeparator = .space
        self.multiValueEncodingStrategy = nil
        self.defaultPosition = .local
    }
}
