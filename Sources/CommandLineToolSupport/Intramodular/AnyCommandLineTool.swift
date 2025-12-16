//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Foundation
import Merge
import Runtime

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
open class AnyCommandLineTool: Logging {
    public lazy var logger = PassthroughLogger(source: self)
    
    /// The name of the command-line tool or information being used.
    ///
    /// By default, the lowercased version of the type name would be used if you don't override it.
    ///
    /// Ideally, it should only contain one argument without whitespaces, for example:
    /// - `xcrun` / `swiftc` / `simctl` / etc.
    /// - `git` / `commit` / `push`, etc.
    open var _commandName: String {
        "\(Self.self)".lowercased()
    }
    
    open var keyConversion: _CommandLineToolOptionKeyConversion? {
        nil
    }
    
    /// Makes the command invocation as it would be passed into system shell.
    ///
    /// - parameter operation: An optional operation after the ``commandName``. It typically serves as mode selection. For example: `xcrun --show-sdk-path -sdk <sdk>` where `--show-sdk-path` is the operation.
    open func makeCommand(operation: String? = nil) -> String {
        _CommandLineToolArgumentBuilder(command: self).buildCommandInvocation(operation: operation)
    }

    public init() {
        
    }

    public var environmentVariables: [String: any CLT.EnvironmentVariableValue] = [:]
    public var currentDirectoryURL: URL? = nil
    
    @discardableResult
    open func withUnsafeSystemShell<R>(
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        let environmentVariables = _resolveEnvironmentVariables()
        
        let shell = SystemShell(
            environment: environmentVariables.mapValues({ String(describing: $0) }),
            currentDirectoryURL: currentDirectoryURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
            options: [._forwardStdoutStderr]
        )
        
        let result: R = try await operation(shell)
        
        return result
    }
    
    /// Makes the command invocation and runs in the system shell
    ///
    /// - parameter operation: An optional operation after the ``commandName``. It typically serves as mode selection. For example: `xcrun --show-sdk-path -sdk <sdk>` where `--show-sdk-path` is the operation.
    @available(*, deprecated, message: "Waiting for @vatsal's `SystemShell` design and this would be an error in the future. Use `withUnsafeSystemShell` instead.")
    @discardableResult
    open func run(operation: String? = nil) async throws -> Process.RunResult {
        try await withUnsafeSystemShell { shell in
            try await shell.run(command: makeCommand(operation: operation))
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AnyCommandLineTool {
    public func withUnsafeSystemShell<R>(
        sink: _ProcessStandardOutputSink,
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        try await withUnsafeSystemShell { shell in
            shell.options ??= []
            shell.options?.removeAll(where: {
                $0._stdoutStderrSink != .null
            })
            shell.options?.append(._forwardStdoutStderr(to: sink))
            
            return try await operation(shell)
        }
    }
}

// MARK: - Auxiliary

extension AnyCommandLineTool {
    /// Resolves the full list of environment variables by combining manually set environment variables with runtime-reflected variables that are defined via the `@EnvironmentVariable` property wrapper.
    private func _resolveEnvironmentVariables() -> [String: any CLT.EnvironmentVariableValue] {
        var result: [String: any CLT.EnvironmentVariableValue] = environmentVariables
        
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children {
            guard let propertyWrapper = child.value as? (any _CommandLineToolEnvironmentVariableProtocol) else {
                continue
            }
            
            let environmentVariableName = propertyWrapper.name
            let environmentVariableValue: any CLT.EnvironmentVariableValue = propertyWrapper.wrappedValue
            
            if environmentVariables.contains(key: environmentVariableName) {
                fatalError("conflict for \(environmentVariableName)")
            }
            
            result[environmentVariableName] = environmentVariableValue
        }
        
        return result
    }
    
}
