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
    
    open class var keyConversion: _CommandLineToolOptionKeyConversion? {
        nil
    }
    
    public init() {
        
    }
}

public class EmptyCommandLineToolSubcommand: CommandLineToolCommand {
    public override var _commandName: String {
        "Empty Subcommand"
    }
}

public protocol _GenericSubcommandProtocol {
    associatedtype Parent
    
    var parent: Parent { get }
    var name: String { get }
}

@dynamicMemberLookup
public struct GenericSubcommand<Parent, Subcommand, Result>: _GenericSubcommandProtocol where Subcommand: CommandLineToolCommand {
    public let parent: Parent
    public let name: String
    public var subcommand: Subcommand

    public subscript<SubSubcommand: CommandLineToolCommand, ChildResult>(
        dynamicMember keyPath: KeyPath<Subcommand, GenericSubcommand<Subcommand, SubSubcommand, ChildResult>>
    ) -> GenericSubcommand<GenericSubcommand<Parent, Subcommand, Result>, SubSubcommand, ChildResult> {
        let subSubcommand = subcommand[keyPath: keyPath]
        
        return GenericSubcommand<GenericSubcommand<Parent, Subcommand, Result>, SubSubcommand, ChildResult>(
            parent: self,
            name: subSubcommand.name,
            subcommand: subSubcommand.subcommand
        )
    }
    
    public func resolve(
        in context: _CommandLineToolResolutionContext
    ) throws -> _ResolvedCommandLineToolDescription {
        try subcommand.resolve(in: context)
    }
    
    public init(
        parent: Parent,
        name: String,
        subcommand: Subcommand
    ) {
        self.parent = parent
        self.name = name
        self.subcommand = subcommand
    }
    
    @discardableResult
    public func callAsFunction() async throws -> Result {
        fatalError(.unimplemented)
    }
    
    public func with<T>(_ keyPath: WritableKeyPath<Subcommand, T>, _ newValue: T) -> Self {
        var copy = self
        copy.subcommand[keyPath: keyPath] = newValue
        return copy
    }
}
