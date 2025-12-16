//
//  GenericSubcommand.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/11.
//

import Foundation
import Swallow
import Merge

public class EmptyCommandLineToolSubcommand: AnyCommandLineTool {
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    public override var _commandName: String {
        name
    }
}

public protocol _GenericSubcommandProtocol {
    associatedtype Parent: AnyCommandLineTool
    var parent: Parent { get }
    
    associatedtype Command: AnyCommandLineTool
    var command: Command { get }
}

@dynamicMemberLookup
public class GenericSubcommand<Parent, Command>: AnyCommandLineTool, _GenericSubcommandProtocol where Parent: AnyCommandLineTool, Command: AnyCommandLineTool {
    public let parent: Parent
    public var command: Command

    public subscript<SubSubcommand: AnyCommandLineTool>(
        dynamicMember keyPath: KeyPath<Command, GenericSubcommand<Command, SubSubcommand>>
    ) -> GenericSubcommand<GenericSubcommand<Parent, Command>, SubSubcommand> {
        let subSubcommand = command[keyPath: keyPath]
        
        return GenericSubcommand<GenericSubcommand<Parent, Command>, SubSubcommand>(
            parent: self,
            command: subSubcommand.command
        )
    }
    
    public init(parent: Parent, command: Command) {
        self.parent = parent
        self.command = command
    }
    
    public override func makeCommand(operation: String? = nil) -> String {
        [parent.makeCommand(operation: nil), command.makeCommand(operation: operation)]
            .joined(separator: " ")
    }
    
    public func with<T>(
        _ keyPath: ReferenceWritableKeyPath<Command, T>,
        _ newValue: T
    ) -> Self {
        command[keyPath: keyPath] = newValue
        return self
    }
    
    @inlinable
    public override func withUnsafeSystemShell<R>(
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        try await command.withUnsafeSystemShell(perform: operation)
    }
}
