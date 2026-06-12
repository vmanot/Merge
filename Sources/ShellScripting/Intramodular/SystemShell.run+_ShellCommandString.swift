//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemShell {
    @discardableResult
    public func run(
        command: _ShellCommandString,
        input: String? = nil,
        interpreter: Environment
    ) async throws -> _ProcessRunResult {
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
    ) async throws -> _ProcessRunResult {
        try await run(
            command: command,
            input: input,
            interpreter: environment
        )
    }
}
