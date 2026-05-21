//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public protocol _ResolvedCommandLineToolInvocationArgument {
    var id: _ResolvedCommandLineToolDescription.ArgumentID { get }
    var defaultPosition: _CommandLineToolArgumentPosition { get }
    var invocationComponents: [_ResolvedCommandLineToolDescription.InvocationComponent] { get }
    var publicInvocationComponents: [CommandLineToolInvocation.Component] { get }
    var invocationArgumentValues: [CommandLineToolInvocation.Argument] { get }
    var invocationArguments: [String] { get }
    var invocationArgument: String? { get }
}

extension _ResolvedCommandLineToolInvocationArgument {
    fileprivate var _resolvedArgumentDescription: String {
        invocationArgument ?? ""
    }

    fileprivate var _resolvedArgumentDebugDescription: String {
        "\(Self.self)(id: \(id.description), resolvedID: \(id.debugDescription), defaultPosition: \(defaultPosition), invocationArguments: \(invocationArguments))"
    }

    fileprivate var _resolvedArgumentCustomMirror: Mirror {
        Mirror(
            self,
            children: [
                "id": id,
                "defaultPosition": defaultPosition,
                "invocationComponents": invocationComponents,
                "publicInvocationComponents": publicInvocationComponents,
                "invocationArgumentValues": invocationArgumentValues,
                "invocationArguments": invocationArguments,
                "invocationArgument": invocationArgument as Any
            ],
            displayStyle: .struct
        )
    }

    public var description: String {
        _resolvedArgumentDescription
    }

    public var debugDescription: String {
        _resolvedArgumentDebugDescription
    }

    public var customMirror: Mirror {
        _resolvedArgumentCustomMirror
    }

    public var invocationArgumentValues: [CommandLineToolInvocation.Argument] {
        invocationComponents.flatMap(\.invocationArgumentValues)
    }

    public var publicInvocationComponents: [CommandLineToolInvocation.Component] {
        invocationComponents.map(\.publicInvocationComponent)
    }

    public var invocationArguments: [String] {
        invocationArgumentValues.map(\.rawValue)
    }

    public var invocationArgument: String? {
        let arguments = invocationArguments.filter { !$0.isEmpty }

        return arguments.isEmpty ? nil : arguments.joined(separator: " ")
    }
}

extension _ResolvedCommandLineToolInvocationArgument {
    package func erasedToAnyResolvedCommandLineToolInvocationArgument() -> _AnyResolvedCommandLineToolInvocationArgument {
        .init(_erasing: self)
    }
}

extension _ResolvedCommandLineToolDescription.Argument {
    public var debugDescription: String {
        _resolvedArgumentDebugDescription
    }
}

extension _ResolvedCommandLineToolDescription.Option {
    public var debugDescription: String {
        _resolvedArgumentDebugDescription
    }
}

extension _ResolvedCommandLineToolDescription.BooleanFlag {
    public var debugDescription: String {
        _resolvedArgumentDebugDescription
    }
}

extension _ResolvedCommandLineToolDescription.CounterFlag {
    public var debugDescription: String {
        _resolvedArgumentDebugDescription
    }
}

extension _ResolvedCommandLineToolDescription.CustomFlag {
    public var debugDescription: String {
        _resolvedArgumentDebugDescription
    }
}

public struct _AnyResolvedCommandLineToolInvocationArgument: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, _UnwrappableTypeEraser, _ResolvedCommandLineToolInvocationArgument, Identifiable {
    public typealias _UnwrappedBaseType = any _ResolvedCommandLineToolInvocationArgument

    public let base: any _ResolvedCommandLineToolInvocationArgument

    public var id: _ResolvedCommandLineToolDescription.ArgumentID {
        base.id
    }

    public var defaultPosition: _CommandLineToolArgumentPosition {
        base.defaultPosition
    }

    public var invocationArgument: String? {
        base.invocationArgument
    }

    public var invocationArguments: [String] {
        base.invocationArguments
    }

    public var invocationComponents: [_ResolvedCommandLineToolDescription.InvocationComponent] {
        base.invocationComponents
    }

    public var publicInvocationComponents: [CommandLineToolInvocation.Component] {
        base.publicInvocationComponents
    }

    public var invocationArgumentValues: [CommandLineToolInvocation.Argument] {
        base.invocationArgumentValues
    }

    public var description: String {
        base.invocationArgument ?? ""
    }

    public var debugDescription: String {
        "_AnyResolvedCommandLineToolInvocationArgument(base: \(String(reflecting: type(of: base))), id: \(id.description), resolvedID: \(id.debugDescription), invocationArguments: \(invocationArguments))"
    }

    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "base": base,
                "id": id,
                "defaultPosition": defaultPosition,
                "invocationComponents": invocationComponents,
                "publicInvocationComponents": publicInvocationComponents,
                "invocationArgumentValues": invocationArgumentValues,
                "invocationArguments": invocationArguments,
                "invocationArgument": invocationArgument as Any
            ],
            displayStyle: .struct
        )
    }

    public init(_erasing x: any _ResolvedCommandLineToolInvocationArgument) {
        self.base = x
    }

    public func _unwrapBase() -> any _ResolvedCommandLineToolInvocationArgument {
        base
    }
}
