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
    
    public typealias ResolvedArguments = IdentifierIndexingArrayOf<_AnyResolvedCommandLineToolMetadata>
    public typealias ResolvedSubcommands = IdentifierIndexingArrayOf<_AnyResolvedCommandLineToolMetadata>
    
    /// A resolved argument.
    public struct Argument: _ResolvedCommandLineToolMetadata {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let position: _CommandLineToolArgumentPosition
        public let value: Any?
        public let valueType: any Any.Type
    }
    
    /// A resolved option.
    public struct Option: _ResolvedCommandLineToolMetadata {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let position: _CommandLineToolArgumentPosition
        public let conversion: _CommandLineToolOptionKeyConversion
        public let name: String
        public let separator: _CommandLineToolParameterKeyValueSeparator
        public let multiValueEncoding: MultiValueParameterEncodingStrategy?
        public let value: Any?
        public let valueType: any Any.Type
    }
    
    /// A resolved simple flag.
    public struct SimpleFlag: _ResolvedCommandLineToolMetadata {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let position: _CommandLineToolArgumentPosition
        public let conversion: _CommandLineToolOptionKeyConversion
        public let name: String
        public let inversion: _CommandLineToolFlagInversion?
        public let defaultBooleanValue: Bool?
        public let isOn: Bool?
    }
    
    /// A resolved custom flag.
    public struct CustomFlag: _ResolvedCommandLineToolMetadata {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let position: _CommandLineToolArgumentPosition
        public let value: Any?
        public let valueType: any Any.Type
    }
    
    /// A resolved subcommand.
    public struct Subcommand: _ResolvedCommandLineToolMetadata {
        public let id: _ResolvedCommandLineToolDescription.ArgumentID
        public let name: String
        public let _resolvedDescription: _ResolvedCommandLineToolDescription
    }
    
    public let toolName: String
    public let arguments: ResolvedArguments
    public let subcommands: ResolvedSubcommands
}

public protocol _ResolvedCommandLineToolMetadata {
    var id: _ResolvedCommandLineToolDescription.ArgumentID { get }
}

extension _ResolvedCommandLineToolMetadata {
    package func erasedToAnyResolvedCommandLineToolMetadata() -> _AnyResolvedCommandLineToolMetadata {
        .init(_erasing: self)
    }
}

public struct _AnyResolvedCommandLineToolMetadata: _UnwrappableTypeEraser, Identifiable {
    public typealias _UnwrappedBaseType = any _ResolvedCommandLineToolMetadata
    
    public let base: any _ResolvedCommandLineToolMetadata
    
    public var id: _ResolvedCommandLineToolDescription.ArgumentID {
        base.id
    }
    
    public init(_erasing x: any _ResolvedCommandLineToolMetadata) {
        self.base = x
    }
    
    public func _unwrapBase() -> any _ResolvedCommandLineToolMetadata {
        base
    }
}
