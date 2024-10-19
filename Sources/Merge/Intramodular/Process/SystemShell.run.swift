//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension SystemShell {
    public func run(
        shell: SystemShell.Environment,
        command: String,
        currentDirectoryURL: URL? = nil,
        environmentVariables: [String: String] = [:]
    ) async throws -> _ProcessResult {
        try await run(
            executableURL: shell.launchURL.unwrap(),
            arguments: shell.deriveArguments(command),
            currentDirectoryURL: nil,
            environment: shell,
            environmentVariables: [:]
        )
    }

    public func run(m
        executablePath: String,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environment: Environment = .zsh,
        environmentVariables: [String: String] = [:]
    ) async throws -> _ProcessResult {
        try await run(
            executableURL: try URL(string: executablePath).unwrap(),
            arguments: arguments,
            currentDirectoryURL: nil,
            environment: environment,
            environmentVariables: [:]
        )
    }
    
    @discardableResult
    public static func run(
        command: String,
        input: String? = nil,
        environment: Environment = .zsh,
        environmentVariables: [String: String] = [:],
        currentDirectoryURL: URL? = nil,
        outputHandler: SystemShell.StandardOutputHandler = .print,
        options: [_AsyncProcessOption]? = nil
    ) async throws -> _ProcessResult {
        try await SystemShell(options: options).run(
            command: command,
            input: input,
            environment: environment,
            environmentVariables: environmentVariables,
            currentDirectoryURL: currentDirectoryURL,
            outputHandler: outputHandler
        )
    }
}
