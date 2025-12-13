//
//  _ResolvedCommandLineToolDescription.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/11.
//

import Foundation
import Swallow
import Collections

/// The most granular and "resolved" representation of a command-line tool within some context.
public struct _ResolvedCommandLineToolDescription {
    public struct ArgumentID: Hashable, Sendable {
        public let rawValue: String // the property name.
    }
    
    public typealias ResolvedArguments = IdentifierIndexingArrayOf<_AnyResolvedCommandLineToolArgument>
    
    /// A resolved argument.
    public struct Argument: _ResolvedCommandLineToolArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let value: Any?
        public let valueType: any Any.Type
    }
    
    /// A resolved option.
    public struct Option: _ResolvedCommandLineToolArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let conversion: _CommandLineToolOptionKeyConversion
        public let name: String
        public let separator: _CommandLineToolParameterKeyValueSeparator
        public let multiValueEncoding: MultiValueParameterEncodingStrategy?
        public let value: Any?
        public let valueType: any Any.Type
    }
    
    /// A resolved simple flag.
    public struct SimpleFlag: _ResolvedCommandLineToolArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let conversion: _CommandLineToolOptionKeyConversion
        public let name: String
        public let inversion: _CommandLineToolFlagInversion?
        public let isOn: Bool?
    }
    
    /// A resolved simple flag.
    public struct CustomFlag: _ResolvedCommandLineToolArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let value: Any?
        public let valueType: any Any.Type
    }
    
    /// A resolved subcommand.
    public struct Subcommand: _ResolvedCommandLineToolArgument {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let name: String
        public let resolvedArguments: ResolvedArguments
        public let returnType: Any.Type
    }
    
    public let toolName: String
    public let arguments: ResolvedArguments
}

public protocol _ResolvedCommandLineToolArgument {
    var id: _ResolvedCommandLineToolDescription.ArgumentID { get }
}

extension _ResolvedCommandLineToolArgument {
    package func erasedToAnyResolvedCommandLineToolArgument() -> _AnyResolvedCommandLineToolArgument {
        .init(_erasing: self)
    }
}

public struct _AnyResolvedCommandLineToolArgument: _UnwrappableTypeEraser, Identifiable {
    public typealias _UnwrappedBaseType = any _ResolvedCommandLineToolArgument
    
    public let base: any _ResolvedCommandLineToolArgument
    
    public var id: _ResolvedCommandLineToolDescription.ArgumentID {
        base.id
    }
    
    public init(_erasing x: any _ResolvedCommandLineToolArgument) {
        self.base = x
    }
    
    public func _unwrapBase() -> any _ResolvedCommandLineToolArgument {
        base
    }
}

