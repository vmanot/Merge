//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension Shell {
    public func run(
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
        progressHandler: Shell.ProgressHandler = .print,
        options: [_AsyncProcessOption]? = nil
    ) async throws -> _ProcessResult {
        try await Shell(options: options).run(
            command: command,
            input: input,
            environment: environment,
            environmentVariables: environmentVariables,
            currentDirectoryURL: currentDirectoryURL,
            progressHandler: progressHandler
        )
    }
}
