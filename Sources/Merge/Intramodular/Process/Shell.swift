//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import AppKit
import Foundation
import Swallow

public final class Shell {
    public let options: [AsyncProcess.Option]
    
    public init(options: [AsyncProcess.Option] = []) {
        self.options = options
    }
    
    private var environmentVariables: [String: String] {
        ProcessInfo.processInfo.environment
    }
    
    @MainActor
    public func run(
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environment: [String: String] = [:]
    ) async throws -> String {
        let process = AsyncProcess(
            progress: .block { _ in },
            options: options + [.reportCompletion]
        )
        
        process.process?.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.process?.currentDirectoryURL = currentDirectoryURL
        process.process?.arguments = arguments
        process.process?.environment = environmentVariables.merging(environment, uniquingKeysWith: { $1 })
        
        try await process.wait()
        
        return process.outputResult
    }
    
    @MainActor
    public func run(
        command: String,
        environment: Environment = .zsh
    ) async throws -> String {
        try await Self.run(
            command: command,
            environment: environment,
            options: options
        )
    }
    
    @discardableResult
    public static func run(
        command: String,
        environment: Environment = .zsh,
        progress: AsyncProcess.Progress = .print,
        input: String? = nil,
        options: [AsyncProcess.Option] = [.reportCompletion, .trimming(.whitespacesAndNewlines), .splitWithNewLine],
        threadIdentifier: String? = nil
    ) async throws -> String {
        var progress = progress
        if case .print = progress {
            progress = .block { text in
                print(text)
            }
        }
        
        let asyncProcess = AsyncProcess(progress: progress, options: options)
        
        let env: Environment.Process = try await environment.env(command: command)
        
        asyncProcess.process?.launchPath = env.launchPath
        asyncProcess.process?.arguments = env.arguments
        
        if let input = input?.data(using: .utf8), !input.isEmpty,
           let handle = asyncProcess.inputPipe?.fileHandleForWriting {
            try? handle.write(contentsOf: input)
            try? handle.close()
        }
        
        try await asyncProcess.wait()
        
        return asyncProcess.outputResult
    }
}

extension Shell {
    public struct Environment {
        var launchPath: String
        var arguments: (_ command: String) -> [String]
        
        public static var bash: Environment {
            .init(launchPath: "/bin/bash", arguments: { ["-c", $0] })
        }
        
        public static var zsh: Environment {
            .init(launchPath: "/bin/zsh", arguments: { ["-c", $0] })
        }
        
        public static var none: Environment {
            .init(launchPath: "", arguments: { _ in [] })
        }
        
        public typealias Process = (launchPath: String, arguments: [String])
        
        public func env(
            command: String
        ) async throws -> Process {
            if !launchPath.isEmpty {
                return (launchPath, arguments(command))
            }
            let commands = command.split(separator: " ")
            var launchPath = ""
            var arguments = [String]()
            if !commands.isEmpty {
                try await Shell.run(command: "which \(commands[0])", progress: .block {
                    launchPath = $0
                })
            }
            if commands.count > 1 {
                try await Shell.run(command: "echo " + commands[1...].joined(separator: " "), environment: .bash, progress: .block {
                    arguments = $0.split(separator: " ").map(String.init)
                })
            }
            return (launchPath, arguments)
        }
    }
}

#endif
