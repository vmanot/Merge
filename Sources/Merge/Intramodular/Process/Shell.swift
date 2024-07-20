//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swallow

@globalActor
public actor _ShellActor {
    public actor ActorType {
        fileprivate init() {
            
        }
    }
    
    public static let shared: ActorType = ActorType()
}

public final class Shell {
    public let options: [_AsyncProcess.Option]?
    
    private var environmentVariables: [String: String] {
        ProcessInfo.processInfo.environment
    }
    
    public init(options: [_AsyncProcess.Option]? = nil) {
        self.options = options
    }
}

extension Shell {
    public func run(
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environmentVariables: [String: String] = [:]
    ) async throws -> _ProcessResult {
        let process = _AsyncProcess(
            arguments: arguments,
            currentDirectoryURL: currentDirectoryURL?._fromURLToFileURL(),
            environmentVariables: self.environmentVariables.merging(environmentVariables, uniquingKeysWith: { $1 }),
            options: options ?? [.reportCompletion]
        )
                
        return try await process.run()
    }
    
    @discardableResult
    public static func run(
        command: String,
        currentDirectoryURL: URL? = nil,
        environment: Environment = .zsh,
        environmentVariables: [String: String] = [:],
        progressHandler: _AsyncProcess.ProgressHandler = .print,
        input: String? = nil,
        options: [_AsyncProcess.Option]? = nil,
        threadIdentifier: String? = nil
    ) async throws -> _ProcessResult {
        let options: [_AsyncProcess.Option] = options ?? [
            .reportCompletion,
            .trimming(.whitespacesAndNewlines),
            .splitWithNewLine
        ]
        
        let process = _AsyncProcess(
            existingProcess: nil,
            progressHandler: progressHandler,
            options: options
        )
        
        let (launchPath, arguments) = try await environment.env(command: command)
        
        if let currentDirectoryURL {
            process.process.currentDirectoryURL = currentDirectoryURL._fromURLToFileURL()
        }
        
        process.process.launchPath = launchPath
        process.process.arguments = arguments
        
        if let input = input?.data(using: .utf8), !input.isEmpty, let handle = process.standardInputPipe?.fileHandleForWriting {
            try? handle.write(contentsOf: input)
            try? handle.close()
        }
        
        return try await process.run()
    }
    
    public func run(
        command: String,
        currentDirectoryURL: URL? = nil,
        environment: Environment = .zsh,
        progressHandler: _AsyncProcess.ProgressHandler = .print
    ) async throws -> _ProcessResult {
        try await Self.run(
            command: command,
            currentDirectoryURL: currentDirectoryURL,
            environment: environment,
            progressHandler: progressHandler,
            options: options
        )
    }
}

#endif
