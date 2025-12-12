//
//  _ResolvedCommandLineToolDescription.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/11.
//

import Foundation
import Swallow

/// The most granular and "resolved" representation of a command-line tool within some context.
public struct _ResolvedCommandLineToolDescription {
    public typealias ResolvedArguments = IdentifierIndexingArrayOf<_AnyResolvedCommandLineToolArgument>
    
    /// A resolved argument.
    public struct Argument: _ResolvedCommandLineToolArgument {
        public let id: _AnyResolvedCommandLineToolArgument.ID
        public let value: CLT.ArgumentValueConvertible
    }
    
    /// A resolved option.
    public struct Option: _ResolvedCommandLineToolArgument {
        public let id: _AnyResolvedCommandLineToolArgument.ID
        public let convertion: _CommandLineToolOptionKeyConversion
        public let name: String
        public let separator: _CommandLineToolParameterKeyValueSeparator
        public let value: Either<[CLT.ArgumentValueConvertible], CLT.ArgumentValueConvertible>
        public let isVariadic: Bool
    }
    
    /// A resolved flag.
    public struct Flag: _ResolvedCommandLineToolArgument {
        public let id: _AnyResolvedCommandLineToolArgument.ID
        public let conversion: _CommandLineToolOptionKeyConversion
        public let name: String
        public let inversion: _CommandLineToolFlagInversion
        public let isOn: Bool
    }
    
    /// A resolved subcommand.
    public struct Subcommand: _ResolvedCommandLineToolArgument {
        public let id: _AnyResolvedCommandLineToolArgument.ID
        public let name: String
        public let resolvedArguments: ResolvedArguments
        public let returnType: Any.Type
    }
    
    public let mainCommandName: String
    public let arguments: ResolvedArguments
}

public protocol _ResolvedCommandLineToolArgument {
    var id: _AnyResolvedCommandLineToolArgument.ID { get }
}

public struct _AnyResolvedCommandLineToolArgument: _UnwrappableTypeEraser, Identifiable {
    public typealias _UnwrappedBaseType = any _ResolvedCommandLineToolArgument
    
    public struct ID: Hashable, Sendable {
        public let index: Int
        public let argument: String
    }
    
    public let base: any _ResolvedCommandLineToolArgument
    
    public var id: _AnyResolvedCommandLineToolArgument.ID {
        base.id
    }
    
    public init(_erasing x: any _ResolvedCommandLineToolArgument) {
        self.base = x
    }
    
    public func _unwrapBase() -> any _ResolvedCommandLineToolArgument {
        base
    }
}

