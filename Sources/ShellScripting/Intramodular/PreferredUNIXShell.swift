//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swift

/// Enum to represent different shell environments or direct execution.
public enum PreferredUNIXShell {
    public enum Name: String, Codable, Hashable, Sendable {
        case sh
        case bash
        case zsh
        case unspecified
    }
}

extension PreferredUNIXShell.Name {
    /// Returns the shell executable path and initial arguments based on the environment.
    func deriveExecutableURLAndArguments(
        fromCommand command: String
    ) -> (executableURL: URL, arguments: [String]) {
        switch self {
            case .sh:
                return (URL(fileURLWithPath: "/bin/sh"), ["-l", "-c", command])
            case .bash:
                return (URL(fileURLWithPath: "/bin/bash"), ["-l", "-c", command])
            case .zsh:
                return (URL(fileURLWithPath: "/bin/zsh"), ["-l", "-c", command])
            case .unspecified:
                fatalError()
        }
    }
}

extension Optional where Wrapped == PreferredUNIXShell.Name {
    func deriveExecutableURLAndArguments(
        fromCommand command: String
    ) -> (executableURL: URL, arguments: [String]) {
        guard let shell = self else {
            return (URL(fileURLWithPath: command), [])
        }
        
        return shell.deriveExecutableURLAndArguments(fromCommand: command)
    }
}

#endif
