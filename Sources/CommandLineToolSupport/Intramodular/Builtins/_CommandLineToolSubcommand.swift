//
//  _CommandLineToolSubcommand.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/11.
//

import Foundation
import Swallow

extension CommandLineTool {
    public typealias Subcommand = _CommandLineToolSubcommand
}

public protocol _CommandLineToolSubcommandProtocol: PropertyWrapper {
    
}

@propertyWrapper
public struct _CommandLineToolSubcommand<Parent, AdditionalArguments, Result>: _CommandLineToolSubcommandProtocol where AdditionalArguments : CommandLineToolOptionGroup {
    public typealias WrappedValue = GenericSubcommand<Parent, AdditionalArguments, Result>
    var _wrappedValue: WrappedValue
    
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            _wrappedValue = newValue
        }
    }
    
    public init(of: Parent.Type, optionGroup: AdditionalArguments, resultType: Result.Type = Void.self) {
        self._wrappedValue = .init(optionGroup: optionGroup)
    }
    
    public init(of: Parent.Type, resultType: Result.Type = Void.self) where AdditionalArguments == EmptyCommandLineToolOptionGroup {
        self._wrappedValue = .init(optionGroup: EmptyCommandLineToolOptionGroup())
    }
}
