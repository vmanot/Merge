//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

#if os(macOS)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension SystemShell {
    public func _runDirectly(
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

    public func _runDirectly(
        executableName: String,
        arguments: [String]
    ) async throws -> Process.RunResult {
        try await _runDirectly(
            executableURL: URL(fileURLWithPath: "/usr/bin/env"),
            arguments: [executableName] + arguments
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
    public func _runDirectly(
        executableURL: URL,
        arguments: [String]
    ) async throws -> _ProcessRunResult {
        throw Never.Reason.unsupported
    }

    public func _runDirectly(
        executableName: String,
        arguments: [String]
    ) async throws -> _ProcessRunResult {
        throw Never.Reason.unsupported
    }
}
#endif
