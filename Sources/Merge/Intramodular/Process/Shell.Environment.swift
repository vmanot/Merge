//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Combine

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
