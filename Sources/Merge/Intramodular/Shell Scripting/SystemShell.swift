//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
public final class SystemShell {
    public var environmentVariables: [String: String]
    public var currentDirectoryURL: URL?
    
    public var options: [_AsyncProcess.Option]?
    
    public init(
        environment: [String: String]? = nil,
        currentDirectoryURL: URL? = nil,
        options: [_AsyncProcess.Option]? = nil
    ) {
        self.environmentVariables = ProcessInfo.processInfo.environment.merging(environment ?? [:], uniquingKeysWith: { lhs, rhs in rhs })
        self.currentDirectoryURL = currentDirectoryURL
        self.options = options
    }
}

#if os(macOS)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension SystemShell {
    public func run(
        executableURL: URL,
        arguments: [String],
        environment: Environment = .zsh
    ) async throws -> Process.RunResult {
        let (launchPath, arguments) = try await environment.resolve(launchPath: executableURL.path, arguments: arguments)
        
        let process = try _AsyncProcess(
            launchPath: launchPath,
            arguments: arguments,
            currentDirectoryURL: currentDirectoryURL?._fromURLToFileURL() ?? self.currentDirectoryURL,
            environmentVariables: self.environmentVariables.merging(environmentVariables, uniquingKeysWith: { $1 }),
            options: options
        )
        
        return try await process.run()
    }
    
    @discardableResult
    public func run(
        command: String,
        input: String? = nil,
        environment: Environment = .zsh
    ) async throws -> Process.RunResult {
        let process = try await _AsyncProcess(
            command: command,
            input: input,
            environment: environmentVariables,
            currentDirectoryURL: currentDirectoryURL,
            options: options
        )
        
        return try await process.run()
    }
}
#else
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension SystemShell {
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
        environment: Environment = .zsh
    ) async throws -> _ProcessRunResult {
        throw Never.Reason.unsupported
    }
}
#endif

// MARK: - Auxiliary

@globalActor
public actor _ShellActor {
    public actor ActorType {
        fileprivate init() {
            
        }
    }
    
    public static let shared: ActorType = ActorType()
}

#if os(macOS)
extension _AsyncProcess {
    public convenience init(
        command: String,
        input: String? = nil,
        shell: SystemShell.Environment = .zsh,
        environment: [String: String]? = nil,
        currentDirectoryURL: URL? = nil,
        options: [_AsyncProcess.Option]?
    ) async throws {
        let (launchPath, arguments) = try await shell.resolve(command: command)
        
        try self.init(
            executableURL: URL(fileURLWithPath: launchPath),
            arguments: arguments,
            environment: environment ?? ProcessInfo.processInfo.environment,
            currentDirectoryURL: currentDirectoryURL,
            options: options
        )
        
        if let input = input?.data(using: .utf8), !input.isEmpty, let handle = standardInputPipe?.fileHandleForWriting {
            try? handle.write(contentsOf: input)
            try? handle.close()
        }
    }
}
#endif

// MARK: - Deprecated

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
@available(*, deprecated, renamed: "SystemShell")
public typealias Shell = SystemShell
