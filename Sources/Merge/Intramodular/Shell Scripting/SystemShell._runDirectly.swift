//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

#if os(macOS)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension SystemShell {
    /// Launches an executable directly, preserving every argument as one argv entry.
    public func run(
        executableURL: URL,
        arguments: [String]
    ) async throws -> Process.RunResult {
        try _validateBorrowedLease()

        let process = try _AsyncProcess(
            executableURL: executableURL,
            arguments: arguments,
            currentDirectoryURL: configuration.currentDirectoryURL,
            environmentVariables: configuration.environmentVariables.resolvingForAsyncProcessLaunch(),
            options: try _optionsForProcessLaunch()
        )

        return try await _run(process)
    }

    /// Resolves an executable through `env`, then launches it without shell parsing.
    public func run(
        executableName: String,
        arguments: [String]
    ) async throws -> Process.RunResult {
        try await run(
            executableURL: URL(fileURLWithPath: "/usr/bin/env"),
            arguments: [executableName] + arguments
        )
    }

    public func run(
        executablePath: String,
        arguments: [String]
    ) async throws -> Process.RunResult {
        try await run(
            executableURL: URL(fileURLWithPath: executablePath),
            arguments: arguments
        )
    }

    @available(*, deprecated, renamed: "run(executableURL:arguments:)")
    public func _runDirectly(
        executableURL: URL,
        arguments: [String]
    ) async throws -> Process.RunResult {
        try await run(executableURL: executableURL, arguments: arguments)
    }

    @available(*, deprecated, renamed: "run(executableName:arguments:)")
    public func _runDirectly(
        executableName: String,
        arguments: [String]
    ) async throws -> Process.RunResult {
        try await run(executableName: executableName, arguments: arguments)
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
        arguments: [String]
    ) async throws -> _ProcessRunResult {
        throw Never.Reason.unsupported
    }

    public func run(
        executableName: String,
        arguments: [String]
    ) async throws -> _ProcessRunResult {
        throw Never.Reason.unsupported
    }

    public func run(
        executablePath: String,
        arguments: [String]
    ) async throws -> _ProcessRunResult {
        throw Never.Reason.unsupported
    }

    @available(*, deprecated, renamed: "run(executableURL:arguments:)")
    public func _runDirectly(
        executableURL: URL,
        arguments: [String]
    ) async throws -> _ProcessRunResult {
        try await run(executableURL: executableURL, arguments: arguments)
    }

    @available(*, deprecated, renamed: "run(executableName:arguments:)")
    public func _runDirectly(
        executableName: String,
        arguments: [String]
    ) async throws -> _ProcessRunResult {
        try await run(executableName: executableName, arguments: arguments)
    }
}
#endif
