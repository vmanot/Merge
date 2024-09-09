//
// Copyright (c) Vatsal Manot
//

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
    public var currentDirectoryURL: URL?

    public let options: [_AsyncProcessOption]?
        
    private var environmentVariables: [String: String] {
        ProcessInfo.processInfo.environment
    }
    
    public init(currentDirectoryURL: URL? = nil, options: [_AsyncProcessOption]? = nil) {
        self.currentDirectoryURL = currentDirectoryURL
        self.options = options
    }
}

#if os(macOS)
extension Shell {
    public func run(
        executableURL: URL,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environment: Environment = .zsh,
        environmentVariables: [String: String] = [:]
    ) async throws -> _ProcessResult {
        let (launchPath, arguments) = try await environment.resolve(launchPath: executableURL.path, arguments: arguments)

        let process = try _AsyncProcess(
            launchPath: launchPath,
            arguments: arguments,
            currentDirectoryURL: currentDirectoryURL?._fromURLToFileURL() ?? self.currentDirectoryURL,
            environmentVariables: self.environmentVariables.merging(environmentVariables, uniquingKeysWith: { $1 }),
            options: options ?? [.reportCompletion]
        )
        
        return try await process.run()
    }
    
    @discardableResult
    public func run(
        command: String,
        input: String? = nil,
        environment: Environment = .zsh,
        environmentVariables: [String: String] = [:],
        currentDirectoryURL: URL? = nil,
        progressHandler: Shell.ProgressHandler = .print
    ) async throws -> _ProcessResult {
        let options: [_AsyncProcessOption] = options ?? [
            .reportCompletion,
            .trimming(.whitespacesAndNewlines),
            .splitWithNewLine
        ]
        
        let (launchPath, arguments) = try await environment.resolve(command: command)
        
        let process = try _AsyncProcess(
            executableURL: URL(fileURLWithPath: launchPath),
            arguments: arguments,
            environment: self.environmentVariables.merging(environmentVariables, uniquingKeysWith: { $1 }),
            currentDirectoryURL: currentDirectoryURL ?? self.currentDirectoryURL,
            progressHandler: progressHandler,
            options: options
        )
        
        if let input = input?.data(using: .utf8), !input.isEmpty, let handle = process.standardInputPipe?.fileHandleForWriting {
            try? handle.write(contentsOf: input)
            try? handle.close()
        }
        
        return try await process.run()
    }
}
#else
extension Shell {
    public func run(
        executableURL: URL,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environment: Environment = .zsh,
        environmentVariables: [String: String] = [:]
    ) async throws -> _ProcessResult {
        throw Never.Reason.unsupported
    }
    
    @discardableResult
    public func run(
        command: String,
        input: String? = nil,
        environment: Environment = .zsh,
        environmentVariables: [String: String] = [:],
        currentDirectoryURL: URL? = nil,
        progressHandler: Shell.ProgressHandler = .print
    ) async throws -> _ProcessResult {
        throw Never.Reason.unsupported
    }
}
#endif

// MARK: - Auxiliary

extension Shell {
    public enum ProgressHandler {
        public typealias Block = (_ text: String) -> Void
        
        public enum ScriptOption: Equatable {
            case login
            case delay(_ timeinterval: TimeInterval)
            case waitUntilFinish
            case closeScriptInside
        }
        
        case print
        case block(
            output: Block,
            error: Block? = nil
        )
        
        public static var empty: Self {
            .block(output: { _ in }, error: nil)
        }
    }
}
