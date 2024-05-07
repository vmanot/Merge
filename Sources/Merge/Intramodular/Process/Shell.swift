//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swallow

public final class Shell {
    public let options: [_UnsafeAsyncProcess.Option]?
    
    private var environmentVariables: [String: String] {
        ProcessInfo.processInfo.environment
    }
    
    public init(options: [_UnsafeAsyncProcess.Option]? = nil) {
        self.options = options
    }
}

extension Shell {
    public func run(
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environment: [String: String] = [:]
    ) async throws -> _UnsafeAsyncProcess.Output {
        let process = _UnsafeAsyncProcess(
            progress: .block { _ in },
            options: options ?? [.reportCompletion]
        )
        
        process.process?.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.process?.currentDirectoryURL = currentDirectoryURL?._fromURLToFileURL()
        process.process?.arguments = arguments
        process.process?.environment = environmentVariables.merging(environment, uniquingKeysWith: { $1 })
        
        return try await process.wait()
    }
    
    @discardableResult
    public static func run(
        command: String,
        currentDirectoryURL: URL? = nil,
        environment: Environment = .zsh,
        progress: _UnsafeAsyncProcess.Progress = .print,
        input: String? = nil,
        options: [_UnsafeAsyncProcess.Option]? = nil,
        threadIdentifier: String? = nil
    ) async throws -> _UnsafeAsyncProcess.Output {
        let options: [_UnsafeAsyncProcess.Option] = options ?? [
            .reportCompletion,
            .trimming(.whitespacesAndNewlines),
            .splitWithNewLine
        ]
        
        var progress = progress
        
        if case .print = progress {
            progress = .block { text in
                print(text)
            }
        }
        
        let process = _UnsafeAsyncProcess(progress: progress, options: options)
        
        let (launchPath, arguments) = try await environment.env(command: command)
        
        if let currentDirectoryURL {
            process.process!.currentDirectoryURL = currentDirectoryURL._fromURLToFileURL()
        }
        
        process.process!.launchPath = launchPath
        process.process!.arguments = arguments
        
        if let input = input?.data(using: .utf8), !input.isEmpty,
           let handle = process.inputPipe?.fileHandleForWriting {
            try? handle.write(contentsOf: input)
            try? handle.close()
        }
        
        return try await process.wait()
    }
    
    public func run(
        command: String,
        currentDirectoryURL: URL? = nil,
        environment: Environment = .zsh
    ) async throws -> _UnsafeAsyncProcess.Output {
        try await Self.run(
            command: command,
            currentDirectoryURL: currentDirectoryURL,
            environment: environment,
            options: options
        )
    }
}

#endif

