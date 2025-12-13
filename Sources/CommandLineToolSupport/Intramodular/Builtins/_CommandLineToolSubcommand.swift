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
    associatedtype Subcommand : CommandLineToolCommand
    associatedtype Result
    
    var name: String { get }
    var subcommand: Subcommand { get }
}

@propertyWrapper
public struct _CommandLineToolSubcommand<Parent, Subcommand, Result> where Subcommand: CommandLineToolCommand {
    public var name: String
    public var subcommand: Subcommand

    public typealias WrappedValue = GenericSubcommand<Parent, Subcommand, Result>
    @available(*, deprecated, message: "This must never be accessed directly. Use this property inside a `class` instead.")
    public var wrappedValue: WrappedValue {
        fatalError(.unavailable)
    }
    
    public static subscript(
        _enclosingInstance parent: Parent,
        wrapped wrappedKeyPath: KeyPath<Parent, WrappedValue>,
        storage storageKeyPath: KeyPath<Parent, Self>
    ) -> WrappedValue {
        let subcommandPropertyWrapper = parent[keyPath: storageKeyPath]
        
        return GenericSubcommand(
            parent: parent,
            name: subcommandPropertyWrapper.name,
            subcommand: subcommandPropertyWrapper.subcommand
        )
    }

    private static func deriveSubcommandName(
        from keyPath: AnyKeyPath
    ) -> String {
        // describing a keypath would be `\.command._subcommand`, the prefix `_` is becuase property wrappper uses `_` as prefix.
        String(describing: keyPath)
            .dropPrefixIfPresent("\\\(Parent.self)._")
    }
    
    public init(
        of parent: Parent.Type,
        name: String,
        subcommand: Subcommand,
        resultType: Result.Type = Void.self
    ) {
        self.name = name
        self.subcommand = subcommand
    }
    
    public init(
        of parent: Parent.Type,
        name: String,
        resultType: Result.Type = Void.self
    ) where Subcommand == EmptyCommandLineToolSubcommand {
        self.name = name
        self.subcommand = .init()
    }
}
