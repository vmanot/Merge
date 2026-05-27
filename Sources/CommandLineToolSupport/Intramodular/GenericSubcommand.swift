//
// Copyright (c) Vatsal Manot
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
    var name: CommandLineTool.Name

    init(name: CommandLineTool.Name) {
        self.name = name
    }

    public override var commandName: CommandLineTool.Name? {
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
    var subcommandName: CommandLineTool.Name? { get }
}

extension _GenericSubcommandProtocol {
    var _opaqueParent: AnyCommandLineTool {
        parent
    }

    var _opaqueCommand: AnyCommandLineTool {
        command
    }
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
    public let subcommandName: CommandLineTool.Name?

    public override var commandName: CommandLineTool.Name? {
        subcommandName ?? command.commandName
    }

    public subscript<SubSubcommand: AnyCommandLineTool>(
        dynamicMember keyPath: KeyPath<Command, GenericSubcommand<Command, SubSubcommand>>
    ) -> GenericSubcommand<GenericSubcommand<Parent, Command>, SubSubcommand> {
        let subSubcommand = command[keyPath: keyPath]

        return GenericSubcommand<GenericSubcommand<Parent, Command>, SubSubcommand>(
            parent: self,
            command: subSubcommand.command,
            subcommandName: subSubcommand.subcommandName
        )
    }

    public init(
        parent: Parent,
        command: Command,
        subcommandName: CommandLineTool.Name? = nil
    ) {
        self.parent = parent
        self.command = command
        self.subcommandName = subcommandName
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

    public func callAsFunction() -> Self {
        self
    }

    @inlinable
    public override func withUnsafeSystemShell<R>(
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        try await command.withUnsafeSystemShell(perform: operation)
    }

    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func callAsFunction() async throws -> Process.RunResult {
        try await withUnsafeSystemShell { shell in
            try await shell.run(command: self.invocation)
        }
    }
}
