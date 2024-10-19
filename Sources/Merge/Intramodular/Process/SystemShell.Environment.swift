//
// Copyright (c) Vatsal Manot
//

import Foundation
import Combine
import Swallow

extension SystemShell {
    public struct Environment {
        let launchPath: String?
        let deriveArguments: (_ command: String) -> [String]
        
        var launchURL: URL? {
            guard let launchPath else {
                return nil
            }
            
            return URL(fileURLWithPath: launchPath)
        }
    }
}

extension SystemShell.Environment {
    func resolve(
        launchPath: String,
        arguments: [String]
    ) async throws -> (launchPath: String, arguments: [String]) {
        /// Handle the case where the the provide path and arguments are `"/bin/zsh"` and `["-l", "-c", "..."].
        if launchPath == self.launchPath, let lastArgument = arguments.last, arguments == self.deriveArguments(arguments.last!) {
            return try await resolve(command: lastArgument)
        } else {
            return try await resolve(command: "\(launchPath) \(arguments.joined(separator: " "))")
        }
    }
    
    func resolve(
        command: String
    ) async throws -> (launchPath: String, arguments: [String]) {
        if let launchPath = launchPath {
            return (launchPath, deriveArguments(command))
        } else {
            let commands: [String.SubSequence] = command.split(separator: " ")
            
            assert(!commands.isEmpty)
            
            let launchPath: String = try await _memoize(uniquingWith: commands[0]) {
                let result = try await resolveLaunchPath(from: String(commands[0]))
                
                return result
            }
            
            var arguments = [String]()
            
            if commands.count > 1 {
                try await SystemShell.run(
                    command: "echo " + commands[1...].joined(separator: " "),
                    environment: .bash,
                    outputHandler: .block {
                        arguments = $0.split(separator: " ").map(String.init)
                    }
                )
            }
            
            return (launchPath, arguments)
        }
    }
    
    private func resolveLaunchPath(
        from x: String
    ) async throws -> String {
        var result: String = ""
        
        try await SystemShell.run(
            command: "which \(x)",
            outputHandler: .block {
                result = $0
            }
        )
        
        return result
    }
}

// MARK: - Initializers

extension SystemShell.Environment {
    public static var bash: Self {
        Self(
            launchPath: "/bin/bash",
            deriveArguments: { ["-c", $0] }
        )
    }
    
    public static var zsh: Self {
        Self(
            launchPath: "/bin/zsh",
            deriveArguments: { ["-l", "-c", $0] }
        )
    }
    
    public static var none: Self {
        Self(launchPath: nil, deriveArguments: { _ in [] })
    }
}
