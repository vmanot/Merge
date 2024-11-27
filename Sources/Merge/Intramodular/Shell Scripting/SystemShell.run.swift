//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemShell {
    public func run(
        shell: SystemShell.Environment,
        command: String
    ) async throws -> _ProcessRunResult {
        try await run(
            executableURL: shell.launchURL.unwrap(),
            arguments: shell.deriveArguments(command),
            environment: shell
        )
    }
    
    public func run(
        executablePath: String,
        arguments: [String],
        environment: Environment = .zsh
    ) async throws -> _ProcessRunResult {
        try await run(
            executableURL: try URL(string: executablePath).unwrap(),
            arguments: arguments,
            environment: environment
        )
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemShell {
    @discardableResult
    public static func run(
        command: String,
        input: String? = nil,
        environment: Environment = .zsh,
        environmentVariables: [String: String] = [:],
        currentDirectoryURL: URL? = nil,
        options: [_AsyncProcess.Option]? = nil
    ) async throws -> _ProcessRunResult {
        let shell = SystemShell(options: options)
            
        shell.environmentVariables.merge(environmentVariables, uniquingKeysWith: { lhs, rhs in rhs })
        shell.currentDirectoryURL = currentDirectoryURL
        
        let result: _ProcessRunResult = try await shell.run(
            command: command,
            input: input,
            environment: environment
        )
        
        return result
    }
}
