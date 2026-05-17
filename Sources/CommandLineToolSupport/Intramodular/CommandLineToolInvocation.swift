#if os(macOS)
//
// Copyright (c) Vatsal Manot
//

import Foundation

/// A structured representation of a rendered command-line tool invocation.
///
/// This preserves the existing shell-rendered component model used by
/// ``CommandLineTool/invocation`` while giving clients a typed value they can
/// inspect before choosing how to execute or display the command.
public struct CommandLineToolInvocation: CustomStringConvertible, Hashable, Sendable {
    /// The shell-rendered invocation components, including the command name.
    public var components: [String]

    public init(components: [String]) {
        self.components = components.filter { !$0.isEmpty }
    }

    /// The rendered command name component, when present.
    public var commandName: String? {
        components.first
    }

    /// The rendered argument components after the command name.
    public var arguments: [String] {
        Array(components.dropFirst())
    }

    /// The shell-rendered command line.
    public var commandLine: String {
        components.joined(separator: " ")
    }

    public var description: String {
        commandLine
    }
}

extension CommandLineTools {
    public typealias Invocation = CommandLineToolInvocation
}

extension CommandLineTool {
    /// A structured representation of this tool's rendered invocation.
    public var commandInvocation: CommandLineToolInvocation {
        get throws {
            try CommandLineToolInvocation(
                components: invocationArguments(context: CommandLineToolInvocationSummary.InvocationSummaryContext())
            )
        }
    }

    /// The shell-rendered invocation components, including the command name.
    public var invocationComponents: [String] {
        get throws {
            try commandInvocation.components
        }
    }
}

#endif
