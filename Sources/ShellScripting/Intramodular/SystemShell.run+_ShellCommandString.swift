//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Merge

extension SystemShell {
    @discardableResult
    public func run(
        command: _ShellCommandString,
        input: String? = nil,
        interpreter: Environment
    ) async throws -> Process.RunResult {
        try await run(
            command: command.rawValue,
            input: input,
            interpreter: interpreter
        )
    }

    @discardableResult
    public func run(
        command: _ShellCommandString,
        input: String? = nil,
        environment: Environment = .zsh
    ) async throws -> Process.RunResult {
        try await run(
            command: command,
            input: input,
            interpreter: environment
        )
    }
}

#endif
