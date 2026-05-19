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
public struct CommandLineToolInvocation: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
    public struct Argument: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable, ExpressibleByStringLiteral {
        public enum Storage: CustomStringConvertible, CustomDebugStringConvertible, Hashable, Sendable {
            case string(String)
            case rawBytes([UInt8])

            public var description: String {
                switch self {
                    case .string(let value):
                        value
                    case .rawBytes(let value):
                        String(decoding: value, as: UTF8.self)
                }
            }

            public var debugDescription: String {
                switch self {
                    case .string(let value):
                        ".string(\(String(reflecting: value)))"
                    case .rawBytes(let value):
                        ".rawBytes(\(value))"
                }
            }
        }

        public var storage: Storage

        public init(storage: Storage) {
            self.storage = storage
        }

        public init(_ value: String) {
            self.init(storage: .string(value))
        }

        public init(rawBytes: [UInt8]) {
            self.init(storage: .rawBytes(rawBytes))
        }

        public init(stringLiteral value: String) {
            self.init(value)
        }

        public var stringValue: String? {
            switch storage {
                case .string(let value):
                    value
                case .rawBytes(let value):
                    String(bytes: value, encoding: .utf8)
            }
        }

        public var rawValue: String {
            switch storage {
                case .string(let value):
                    value
                case .rawBytes(let value):
                    String(decoding: value, as: UTF8.self)
            }
        }

        public var rawBytes: [UInt8] {
            switch storage {
                case .string(let value):
                    Array(value.utf8)
                case .rawBytes(let value):
                    value
            }
        }

        public var posixShellEscapedValue: String {
            guard !rawValue.isEmpty else {
                return "''"
            }

            return "'" + rawValue.replacingOccurrences(of: "'", with: "'\\''") + "'"
        }

        public var description: String {
            rawValue
        }

        public var debugDescription: String {
            "CommandLineToolInvocation.Argument(\(storage.debugDescription))"
        }

        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "storage": storage,
                    "stringValue": stringValue as Any,
                    "rawValue": rawValue,
                    "rawBytes": rawBytes
                ],
                displayStyle: .struct
            )
        }
    }

    /// The semantic invocation arguments, including the command name.
    public var components: [Argument]

    public init(components: [String]) {
        self.components = components
            .filter { !$0.isEmpty }
            .map { Argument($0) }
    }

    public init(components: [Argument]) {
        self.components = components
    }

    public var rawComponents: [String] {
        components.map(\.rawValue)
    }

    /// The rendered command name component, when present.
    public var commandName: String? {
        components.first?.rawValue
    }

    /// The semantic argument components after the command name.
    public var arguments: [Argument] {
        Array(components.dropFirst())
    }

    /// The shell-rendered display command line.
    public var commandLine: String {
        rawComponents.joined(separator: " ")
    }

    public var posixShellCommandLine: String {
        components
            .map(\.posixShellEscapedValue)
            .joined(separator: " ")
    }

    public var description: String {
        commandLine
    }

    public var debugDescription: String {
        "CommandLineToolInvocation(\(String(reflecting: commandLine)))"
    }

    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "components": components,
                "rawComponents": rawComponents,
                "commandName": commandName as Any,
                "arguments": arguments,
                "commandLine": commandLine
            ],
            displayStyle: .struct
        )
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

    /// The semantic invocation arguments, including the command name.
    public var invocationComponents: [CommandLineToolInvocation.Argument] {
        get throws {
            try commandInvocation.components
        }
    }
}

#endif
