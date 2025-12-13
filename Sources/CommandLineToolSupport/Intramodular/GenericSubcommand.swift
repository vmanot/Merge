//
//  GenericSubcommand.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/11.
//

import Foundation
import Swallow

open class CommandLineToolCommand {
    /// The name of the command-line tool or information being used.
    ///
    /// By default, the lowercased version of the type name would be used if you don't override it.
    ///
    /// Ideally, it should only contain one argument without whitespaces, for example:
    /// - `xcrun` / `swiftc` / `simctl` / etc.
    /// - `git` / `commit` / `push`, etc.
    open var _commandName: String {
        "\(Self.self)".lowercased()
    }
    
    open var keyConversion: _CommandLineToolOptionKeyConversion? {
        nil
    }
    
    /// Makes the command invocation as it would be passed into system shell.
    ///
    /// - parameter operation: An optional operation after the ``commandName``. It typically serves as mode selection. For example: `xcrun --show-sdk-path -sdk <sdk>` where `--show-sdk-path` is the operation.
    open func makeCommand(operation: String? = nil) -> String {
        _CommandLineToolArgumentBuilder(command: self).buildCommandInvocation(operation: operation)
    }

    public init() {
        
    }
}

public class EmptyCommandLineToolSubcommand: CommandLineToolCommand {
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    public override var _commandName: String {
        name
    }
}

public protocol _GenericSubcommandProtocol {
    associatedtype Parent
    var parent: Parent { get }
    
    func makeCommand(operation: String?) -> String
}

@dynamicMemberLookup
public struct GenericSubcommand<Parent, Command, Result>: _GenericSubcommandProtocol where Command: CommandLineToolCommand {
    public let parent: Parent
    public var command: Command

    public subscript<SubSubcommand: CommandLineToolCommand, ChildResult>(
        dynamicMember keyPath: KeyPath<Command, GenericSubcommand<Command, SubSubcommand, ChildResult>>
    ) -> GenericSubcommand<Self, SubSubcommand, ChildResult> {
        let subSubcommand = command[keyPath: keyPath]
        
        return GenericSubcommand<Self, SubSubcommand, ChildResult>(
            parent: self,
            command: subSubcommand.command
        )
    }
    
    public func resolve(
        in context: _CommandLineToolResolutionContext
    ) throws -> _ResolvedCommandLineToolDescription {
        try command.resolve(in: context)
    }
    
    public func makeCommand(
        operation: String? = nil
    ) -> String {
        var invocationComponents = [String]()
        
        if let parent = parent as? AnyCommandLineTool {
            invocationComponents.append(parent.makeCommand())
        } else if let parent = parent as? (any _GenericSubcommandProtocol) {
            invocationComponents.append(parent.makeCommand(operation: nil))
        }
        
        invocationComponents.append(command.makeCommand(operation: operation))
        
        return invocationComponents.joined(separator: " ")
    }
    
    public init(parent: Parent, command: Command) {
        self.parent = parent
        self.command = command
    }
    
    @discardableResult
    public func callAsFunction() async throws -> Result {
        fatalError(.unimplemented)
    }
    
    public func with<T>(_ keyPath: WritableKeyPath<Command, T>, _ newValue: T) -> Self {
        var copy = self
        copy.command[keyPath: keyPath] = newValue
        return copy
    }
}
