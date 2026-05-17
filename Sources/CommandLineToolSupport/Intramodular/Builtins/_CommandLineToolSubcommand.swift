#if os(macOS)
//
//  _CommandLineToolSubcommand.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/11.
//

import Foundation
import Swallow

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineTool {
    public typealias Subcommand = _CommandLineToolSubcommand
}

public protocol _CommandLineToolSubcommandProtocol /* PropertyWrapper */ {
    associatedtype Subcommand : AnyCommandLineTool
    
    var name: String { get }
    var command: Subcommand { get }
}

@propertyWrapper
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct _CommandLineToolSubcommand<Parent, Command>: _CommandLineToolSubcommandProtocol where Parent: AnyCommandLineTool, Command: AnyCommandLineTool & CommandLineTool {
    public var name: String
    public var command: Command

    public typealias WrappedValue = GenericSubcommand<Parent, Command>
    
    @available(*, unavailable, message: "This must never be accessed directly. Use this property inside a `class` instead.")
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
            command: subcommandPropertyWrapper.command
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
        command: Command
    ) {
        self.name = name
        self.command = command
    }
    
    public init(
        of parent: Parent.Type,
        name: String
    ) where Command == EmptyCommandLineToolSubcommand {
        self.name = name
        self.command = .init(name: name)
    }
}

#endif
