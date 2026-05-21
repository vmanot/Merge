//
// Copyright (c) Vatsal Manot
//


import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Records whether execution came from a modeled invocation or an intentionally raw shell command line.
public enum _CommandLineToolExecutionSource: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
    case modeledInvocation(CommandLineToolInvocation)
    case shellCommandLine(String)
}

extension _CommandLineToolExecutionSource {
    public var description: String {
        commandLine
    }

    public var debugDescription: String {
        switch self {
            case .modeledInvocation(let invocation):
                "_CommandLineToolExecutionSource.modeledInvocation(\(invocation.debugDescription))"
            case .shellCommandLine(let commandLine):
                "_CommandLineToolExecutionSource.shellCommandLine(\(String(reflecting: commandLine)))"
        }
    }

    public var customMirror: Mirror {
        switch self {
            case .modeledInvocation(let invocation):
                Mirror(
                    self,
                    children: [
                        "case": "modeledInvocation",
                        "invocation": invocation,
                        "commandLine": commandLine
                    ],
                    displayStyle: .enum
                )
            case .shellCommandLine(let commandLine):
                Mirror(
                    self,
                    children: [
                        "case": "shellCommandLine",
                        "commandLine": commandLine
                    ],
                    displayStyle: .enum
                )
        }
    }

    public var commandLine: String {
        switch self {
            case .modeledInvocation(let invocation):
                invocation.commandLine
            case .shellCommandLine(let commandLine):
                commandLine
        }
    }

    public var invocation: CommandLineToolInvocation? {
        switch self {
            case .modeledInvocation(let invocation):
                invocation
            case .shellCommandLine:
                nil
        }
    }
}

