//
// Copyright (c) Vatsal Manot
//

import Foundation
import Combine
import Swallow

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
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

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension SystemShell.Environment {
    public func resolve(
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
    
    public func resolve(
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
                arguments = try await SystemShell.run(
                    command: "echo " + commands[1...].joined(separator: " "),
                    environment: .bash
                )
                .stdoutString
                .unwrap()
                .split(separator: " ")
                .map(String.init)
            }
            
            return (launchPath, arguments)
        }
    }
    
    private func resolveLaunchPath(
        from x: String
    ) async throws -> String {
        let result: String = try await SystemShell.run(command: "which \(x)").stdoutString.unwrap()
        
        return result
    }
}

// MARK: - Initializers

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
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
