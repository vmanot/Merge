//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

#if os(macOS)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension SystemShell {
    public func run(
        executableURL: URL,
        arguments: [String],
        interpreter: Environment
    ) async throws -> Process.RunResult {
        try _validateBorrowedLease()

        let (launchPath, arguments) = try await interpreter.resolve(launchPath: executableURL.path, arguments: arguments)

        let process = try _AsyncProcess(
            launchPath: launchPath,
            arguments: arguments,
            currentDirectoryURL: configuration.currentDirectoryURL,
            environmentVariables: configuration.environmentVariables.resolvingForAsyncProcessLaunch(),
            options: try _optionsForProcessLaunch()
        )

        return try await _run(process)
    }

    public func run(
        executableURL: URL,
        arguments: [String],
        environment: Environment = .zsh
    ) async throws -> Process.RunResult {
        try await run(
            executableURL: executableURL,
            arguments: arguments,
            interpreter: environment
        )
    }

    @discardableResult
    public func run(
        command: String,
        input: String? = nil,
        interpreter: Environment
    ) async throws -> Process.RunResult {
        try _validateBorrowedLease()

        let process = try await _AsyncProcess(
            command: command,
            input: input,
            environmentVariables: configuration.environmentVariables.resolvingForAsyncProcessLaunch(),
            currentDirectoryURL: configuration.currentDirectoryURL,
            options: try _optionsForProcessLaunch()
        )

        return try await _run(process)
    }

    @discardableResult
    public func run(
        command: String,
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
#else
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemShell {
    public func run(
        executableURL: URL,
        arguments: [String],
        interpreter: Environment
    ) async throws -> _ProcessRunResult {
        throw Never.Reason.unsupported
    }

    public func run(
        executableURL: URL,
        arguments: [String],
        environment: Environment = .zsh
    ) async throws -> _ProcessRunResult {
        throw Never.Reason.unsupported
    }

    @discardableResult
    public func run(
        command: String,
        input: String? = nil,
        interpreter: Environment
    ) async throws -> _ProcessRunResult {
        throw Never.Reason.unsupported
    }

    @discardableResult
    public func run(
        command: String,
        input: String? = nil,
        environment: Environment = .zsh
    ) async throws -> _ProcessRunResult {
        throw Never.Reason.unsupported
    }
}
#endif

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
            interpreter: shell
        )
    }

    public func run(
        executablePath: String,
        arguments: [String],
        interpreter: Environment
    ) async throws -> _ProcessRunResult {
        try await run(
            executableURL: try URL(string: executablePath).unwrap(),
            arguments: arguments,
            interpreter: interpreter
        )
    }

    public func run(
        executablePath: String,
        arguments: [String],
        environment: Environment = .zsh
    ) async throws -> _ProcessRunResult {
        try await run(
            executablePath: executablePath,
            arguments: arguments,
            interpreter: environment
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
        interpreter: Environment,
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
            interpreter: interpreter
        )

        return result
    }

    @discardableResult
    public static func run(
        command: String,
        input: String? = nil,
        environment: Environment = .zsh,
        environmentVariables: [String: String] = [:],
        currentDirectoryURL: URL? = nil,
        options: [_AsyncProcess.Option]? = nil
    ) async throws -> _ProcessRunResult {
        try await run(
            command: command,
            input: input,
            interpreter: environment,
            environmentVariables: environmentVariables,
            currentDirectoryURL: currentDirectoryURL,
            options: options
        )
    }
}
