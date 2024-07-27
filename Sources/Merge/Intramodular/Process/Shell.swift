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
    public let options: [_AsyncProcessOption]?
    
    private var environmentVariables: [String: String] {
        ProcessInfo.processInfo.environment
    }
    
    public init(options: [_AsyncProcessOption]? = nil) {
        self.options = options
    }
}

#if os(macOS) || targetEnvironment(macCatalyst)
extension Shell {
    public func run(
        executableURL: URL?,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environmentVariables: [String: String] = [:]
    ) async throws -> _ProcessResult {
        let process = try _AsyncProcess(
            executableURL: executableURL,
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
        progressHandler: Shell.ProgressHandler = .print,
        input: String? = nil,
        options: [_AsyncProcessOption]? = nil,
        threadIdentifier: String? = nil
    ) async throws -> _ProcessResult {
        let options: [_AsyncProcessOption] = options ?? [
            .reportCompletion,
            .trimming(.whitespacesAndNewlines),
            .splitWithNewLine
        ]
        
        let (launchPath, arguments) = try await environment.env(command: command)

        let process = try _AsyncProcess(
            executableURL: URL(fileURLWithPath: launchPath),
            arguments: arguments,
            environment: environmentVariables,
            currentDirectoryURL: currentDirectoryURL,
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
        executableURL: URL?,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environmentVariables: [String: String] = [:]
    ) async throws -> _ProcessResult {
        throw Never.Reason.unsupported
    }
    
    @discardableResult
    public static func run(
        command: String,
        currentDirectoryURL: URL? = nil,
        environment: Environment = .zsh,
        environmentVariables: [String: String] = [:],
        progressHandler: Shell.ProgressHandler = .print,
        input: String? = nil,
        options: [_AsyncProcessOption]? = nil,
        threadIdentifier: String? = nil
    ) async throws -> _ProcessResult {
        throw Never.Reason.unsupported
    }
}
#endif

extension Shell {
    public func run(
        executablePath: String?,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environmentVariables: [String: String] = [:]
    ) async throws -> _ProcessResult {
        try await run(
            executableURL: executablePath.map({ try URL(string: $0).unwrap() }),
            arguments: arguments,
            currentDirectoryURL: nil,
            environmentVariables: [:]
        )
    }

    public func run(
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environmentVariables: [String: String] = [:]
    ) async throws -> _ProcessResult {
        try await run(
            executableURL: nil,
            arguments: arguments,
            currentDirectoryURL: nil,
            environmentVariables: [:]
        )
    }
        
    public func run(
        command: String,
        currentDirectoryURL: URL? = nil,
        environment: Environment = .zsh,
        progressHandler: Shell.ProgressHandler = .print
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
