#if os(macOS)
//
//  GenericSubcommand.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/11.
//

import Foundation
import Swallow
import Merge

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public class EmptyCommandLineToolSubcommand: AnyCommandLineTool, CommandLineTool {
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    public override var _commandName: String {
        name
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol _GenericSubcommandProtocol {
    associatedtype Parent: AnyCommandLineTool
    var parent: Parent { get }
    
    associatedtype Command: AnyCommandLineTool
    var command: Command { get }
}

@dynamicMemberLookup
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public class GenericSubcommand<Parent, Command>: AnyCommandLineTool, CommandLineTool, _GenericSubcommandProtocol where Parent: AnyCommandLineTool, Command: AnyCommandLineTool & CommandLineTool {
    public let parent: Parent
    public var command: Command
    
    public override var _commandName: String {
        command._commandName
    }

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
    
    public var invocationSummary: some InvocationSummary {
        command.invocationSummary
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
    
#if os(macOS)
    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func callAsFunction() async throws -> Process.RunResult {
        try await withUnsafeSystemShell { shell in
            try await shell.run(command: command.invocation)
        }
    }
#endif
}

#endif
