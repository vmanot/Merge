//
// Copyright (c) Vatsal Manot
//

import Combine

extension Shell {
    public struct Environment {
        var launchPath: String?
        var deriveArguments: (_ command: String) -> [String]
        
        func resolve(
            launchPath: String,
            arguments: [String]
        ) async throws -> (launchPath: String, arguments: [String]) {
            try await resolve(command: "\(launchPath) \(arguments.joined(separator: " "))")
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
                    try await Shell.run(
                        command: "echo " + commands[1...].joined(separator: " "),
                        environment: .bash,
                        progressHandler: .block {
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
            
            try await Shell.run(
                command: "which \(x)",
                progressHandler: .block {
                    result = $0
                }
            )
            
            return result
        }
    }
}

extension Shell.Environment {
    public static var bash: Self {
        Self(launchPath: "/bin/bash", deriveArguments: { ["-c", $0] })
    }
    
    public static var zsh: Self {
        Self(launchPath: "/bin/zsh", deriveArguments: { ["-l", "-c", $0] })
    }
    
    public static var none: Self {
        Self(launchPath: nil, deriveArguments: { _ in [] })
    }
}
