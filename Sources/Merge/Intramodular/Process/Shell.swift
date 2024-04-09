//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import AppKit
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

extension Shell {
    public struct Environment {
        var launchPath: String
        var arguments: (_ command: String) -> [String]
        
        public func env(
            command: String
        ) async throws -> (launchPath: String, arguments: [String]) {
            if !launchPath.isEmpty {
                return (launchPath, arguments(command))
            }
            
            let commands: [String.SubSequence] = command.split(separator: " ")
            
            assert(!commands.isEmpty)
            
            let launchPath: String = try await _memoize(uniquingWith: commands[0]) {
                try await resolveLaunchPath(from: String(commands[0]))
            }
            
            var arguments = [String]()
            
            if commands.count > 1 {
                try await Shell.run(command: "echo " + commands[1...].joined(separator: " "), environment: .bash, progress: .block {
                    arguments = $0.split(separator: " ").map(String.init)
                })
            }
            
            return (launchPath, arguments)
        }
        
        private func resolveLaunchPath(
            from x: String
        ) async throws -> String {
            var result: String = ""
            
            try await Shell.run(command: "which \(x)", progress: .block {
                result = $0
            })
            
            return result
        }
    }
}

extension Shell.Environment {
    public static var bash: Self {
        Self(launchPath: "/bin/bash", arguments: { ["-c", $0] })
    }
    
    public static var zsh: Self {
        Self(launchPath: "/bin/zsh", arguments: { ["-c", $0] })
    }
    
    public static var none: Self {
        Self(launchPath: "", arguments: { _ in [] })
    }
}

#endif

