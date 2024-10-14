//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swift

extension Process {
    /// Enum to represent different shell environments or direct execution.
    public enum ShellEnvironment {
        case bash
        case zsh
        case unspecified
    }
    
    public struct ArgumentLiteral: Hashable, ExpressibleByStringLiteral, Sendable {
        public enum Option: Hashable, Sendable {
            case escapeSpaces
        }
        
        let value: String
        let options: Set<Option>
        let isQuoted: Bool
        
        public init(
            _ value: String,
            options: Set<Option> = [.escapeSpaces],
            isQuoted: Bool = false
        ) {
            self.value = value
            self.options = options
            self.isQuoted = isQuoted
        }
        
        @_disfavoredOverload
        public init(
            _ value: URL,
            options: Set<Option> = [.escapeSpaces],
            isQuoted: Bool = false
        ) {
            let value: String = value.isFileURL ? value.path : value.absoluteString
          
            self.init(
                value,
                options: options,
                isQuoted: isQuoted
            )
        }

        public init(
            stringLiteral value: String
        ) {
            self.init(value)
        }
        
        /// Returns the argument value with necessary escape characters, optionally wrapped in quotes.
        /// Handles escaping quotes within quoted arguments (Example: Nested Quotes for "echo \"John said, 'Hello'\"").
        public var escapedValue: String {
            var result = value
            
            if isQuoted {
                result = result.replacingOccurrences(of: "\\", with: "\\\\") // First escape backslashes
                result = result.replacingOccurrences(of: "\"", with: "\\\"") // Then escape double quotes
                result = "\"" + result + "\"" // Wrap the whole argument in quotes
            } else {
                result = result.replacingOccurrences(of: "\\", with: "\\\\") // Escape backslashes
                
                if options.contains(.escapeSpaces) {
                    result = result.replacingOccurrences(of: " ", with: "\\ ") // Escape spaces
                }
                
                result = result.replacingOccurrences(of: "'", with: "\\'") // Escape single quotes
                result = result.replacingOccurrences(of: "\"", with: "\\\"") // Escape double quotes
            }
            
            return result
        }
    }
    
    /// Initializes a `Process` to run a command using a specified shell or directly, with given arguments and options.
    public convenience init(
        command: String,
        shell: ShellEnvironment? = .unspecified,
        arguments: [ArgumentLiteral] = [],
        environment: [String: String] = [:],
        currentDirectoryPath: String? = nil
    ) {
        self.init()
        
        var shell: ShellEnvironment? = shell
        
        if shell == .unspecified {
            if command.hasPrefix("/bin") || command.hasPrefix("/usr/bin") {
                shell = nil
            } else {
                shell = .zsh
            }
        }
        
        let shellArguments = shell.shellPathAndArguments(command: command)
        
        self.executableURL = shellArguments.0
        
        let additionalArguments: [String] = arguments.map {
            $0.escapedValue
        }
        
        self.arguments = shellArguments.1 + additionalArguments
        self.environment = ProcessInfo.processInfo.environment.merging(environment) { (_, new) in new }
        
        if let currentDirectoryPath = currentDirectoryPath {
            self.currentDirectoryURL = URL(fileURLWithPath: currentDirectoryPath)
        }
    }
    
    public convenience init(
        _ command: String,
        arguments: [ArgumentLiteral] = [],
        environment: [String: String] = [:],
        currentDirectoryPath: String? = nil
    ) {
        self.init(
            command: command,
            shell: nil,
            arguments: arguments,
            environment: environment,
            currentDirectoryPath: currentDirectoryPath
        )
    }
    
    public convenience init(
        _ command: String,
        arguments: [String] = [],
        environment: [String: String] = [:],
        currentDirectoryPath: String? = nil
    ) {
        self.init(
            command: command,
            shell: .unspecified,
            arguments: arguments.map(Process.ArgumentLiteral.init(stringLiteral:)),
            environment: environment,
            currentDirectoryPath: currentDirectoryPath
        )
    }
    
    public convenience init(
        command: String,
        shell: ShellEnvironment? = .unspecified,
        argumentString: String,
        environment: [String: String] = [:],
        currentDirectoryPath: String? = nil
    ) {
        let splitArguments: [String] = Process.splitArguments(argumentString)
        
        let arguments: [ArgumentLiteral] = splitArguments.map {
            ArgumentLiteral($0,  isQuoted: $0.contains("\"") || $0.contains("'"))
        }
    
        self.init(
            command: command,
            shell: shell,
            arguments: arguments,
            environment: environment,
            currentDirectoryPath: currentDirectoryPath
        )
    }
}

// MARK: - Internal

extension Process.ShellEnvironment {
    /// Returns the shell executable path and initial arguments based on the environment.
    func shellPathAndArguments(
        command: String
    ) -> (path: URL, arguments: [String]) {
        switch self {
            case .bash:
                return (URL(fileURLWithPath: "/bin/bash"), ["-l", "-c", command])
            case .zsh:
                return (URL(fileURLWithPath: "/bin/zsh"), ["-l", "-c", command])
            case .unspecified:
                fatalError()
        }
    }
}

extension Optional where Wrapped == Process.ShellEnvironment {
    func shellPathAndArguments(
        command: String
    ) -> (path: URL, arguments: [String]) {
        guard let shell = self else {
            return (URL(fileURLWithPath: command), [])
        }
        
        return shell.shellPathAndArguments(command: command)
    }
}

extension Process {
    private struct ArgumentStringSplitState {
        var parts: [String] = []
        var currentPart = ""
        var inQuotes = false
        var escaping = false
        var quoteCharacter: Character?
    }
    
    /// Splits a single argument string into multiple arguments by spaces, respecting quoted substrings.
    /// Correctly handles paths and commands with spaces (Example: Path "/Applications/My App.app/Contents/MacOS/app").
    static func splitArguments(_ argument: String) -> [String] {
        var state = ArgumentStringSplitState()
        
        for char in argument {
            processCharacter(char, &state)
        }
        
        // If there is any remaining content in the current part after iterating through all characters
        // Append the current part to the parts array
        // This handles the case where the last argument doesn't have a trailing space
        if !state.currentPart.isEmpty {
            state.parts.append(state.currentPart)
        }
        
        return state.parts
    }
    
    private static func processCharacter(
        _ char: Character,
        _ state: inout ArgumentStringSplitState
    ) {
        if state.escaping {
            handleEscapedCharacter(char, &state)
        } else if char == "\\" && state.inQuotes {
            state.currentPart.append(char)
        } else if char == "\\" {
            handleBackslash(&state)
        } else if char == " " && !state.inQuotes {
            handleSpace(&state)
        } else if char == "\"" || char == "'" {
            handleQuote(char, &state)
        } else {
            handleRegularCharacter(char, &state)
        }
    }
    
    private static func handleEscapedCharacter(
        _ char: Character,
        _ state: inout ArgumentStringSplitState
    ) {
        state.currentPart.append(char)
        state.escaping = false
    }
    
    private static  func handleBackslash(
        _ state: inout ArgumentStringSplitState
    ) {
        state.escaping = true
        state.currentPart.append("\\")
    }
    
    private static func handleSpace(_ state: inout ArgumentStringSplitState) {
        if !state.currentPart.isEmpty {
            state.parts.append(state.currentPart)
            state.currentPart = ""
        }
    }
    
    private static func handleQuote(
        _ char: Character,
        _ state: inout ArgumentStringSplitState
    ) {
        if state.inQuotes {
            if char == state.quoteCharacter && !state.escaping {
                state.inQuotes = false
                state.quoteCharacter = nil
            }
            state.currentPart.append(char)
        } else {
            state.inQuotes = true
            state.quoteCharacter = char
            state.currentPart.append(char)
        }
    }
    
    private static func handleRegularCharacter(
        _ char: Character,
        _ state: inout ArgumentStringSplitState
    ) {
        state.currentPart.append(char)
    }
}

#endif
