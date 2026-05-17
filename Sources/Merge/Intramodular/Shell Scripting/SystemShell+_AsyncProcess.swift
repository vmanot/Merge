//
// Copyright (c) Vatsal Manot
//

import Foundation

@available(macOS 11.0, *)
@available(iOS 13.4, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _AsyncProcess {
    public convenience init(
        command: String,
        input: String? = nil,
        shell: SystemShell.Environment = .zsh,
        environmentVariables: _AsyncProcess.EnvironmentVariables = .inherited,
        currentDirectoryURL: URL? = nil,
        options: [_AsyncProcess.Option]?
    ) async throws {
        let (launchPath, arguments) = try await shell.resolve(command: command)

        try self.init(
            executableURL: URL(fileURLWithPath: launchPath),
            arguments: arguments,
            environmentVariables: environmentVariables,
            currentDirectoryURL: currentDirectoryURL,
            options: options
        )

        if let input = input?.data(using: .utf8), !input.isEmpty, let handle = standardInputPipe?.fileHandleForWriting {
            handle.write(input)
            try? handle.close()
        }
    }

    public convenience init(
        command: String,
        input: String? = nil,
        shell: SystemShell.Environment = .zsh,
        environment: [String: String]?,
        currentDirectoryURL: URL? = nil,
        options: [_AsyncProcess.Option]?
    ) async throws {
        try await self.init(
            command: command,
            input: input,
            shell: shell,
            environmentVariables: environment.map(EnvironmentVariables.exact) ?? .inherited,
            currentDirectoryURL: currentDirectoryURL,
            options: options
        )
    }
}
