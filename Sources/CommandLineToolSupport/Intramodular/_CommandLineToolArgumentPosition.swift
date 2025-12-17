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
        case global
        /// Place the argument alongside a subcommand, after the subcommand component.
        case subcommand
    }
    
    /// The coarse-grained anchor for the argument.
    public var anchor: Anchor
    
    public init(anchor: Anchor) {
        self.anchor = anchor
    }
}

extension _CommandLineToolArgumentPosition {
    public static var global: Self {
        .init(anchor: .global)
    }
    
    public static var subcommand: Self {
        .init(anchor: .subcommand)
    }
}
