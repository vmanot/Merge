#if os(macOS)
//
//  _CommandLineToolArgumentPosition.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/17.
//

import Foundation

/// Describes where a flag or parameter should appear when constructing a command invocation.
public struct _CommandLineToolArgumentPosition: Hashable, Sendable {
    public enum Anchor: Hashable, Sendable {
        /// Place the argument with the global options, before any subcommand-specific component.
        case local
        /// Place the argument in the group of next command
        case nextCommand
        /// Place the argument in the group of last command
        case lastCommand
    }
    
    /// The coarse-grained anchor for the argument.
    public var anchor: Anchor
    
    public init(anchor: Anchor) {
        self.anchor = anchor
    }
}

/// Describes where a flag or parameter should appear when constructing a command invocation.
public typealias CommandLineToolArgumentPlacement = _CommandLineToolArgumentPosition

extension _CommandLineToolArgumentPosition {
    /// Place the argument with the command that declares it.
    public static var declaringCommand: Self {
        .local
    }
    
    /// Place the argument with the command that declares it.
    public static var local: Self {
        .init(anchor: .local)
    }
    
    /// Place the argument with the selected command in a command/subcommand chain.
    public static var selectedCommand: Self {
        .nextCommand
    }
    
    /// Place the argument with the next command in a command/subcommand chain.
    public static var nextCommand: Self {
        .init(anchor: .nextCommand)
    }
    
    /// Place the argument with the final command in a command/subcommand chain.
    public static var finalCommand: Self {
        .lastCommand
    }
    
    /// Place the argument with the final command in a command/subcommand chain.
    public static var lastCommand: Self {
        .init(anchor: .lastCommand)
    }
}

#endif
