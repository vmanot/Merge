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

extension _CommandLineToolArgumentPosition {
    public static var local: Self {
        .init(anchor: .local)
    }
    
    public static var nextCommand: Self {
        .init(anchor: .nextCommand)
    }
    
    public static var lastCommand: Self {
        .init(anchor: .lastCommand)
    }
}
