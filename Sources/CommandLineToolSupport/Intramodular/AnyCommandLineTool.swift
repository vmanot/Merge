//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
open class AnyCommandLineTool {
    public var environmentVariables: [String: any CLT.EnvironmentVariableValue] = [:]
    public var currentDirectoryURL: URL? = nil
    
    public init() {
        
    }
    
    @discardableResult
    open func withUnsafeSystemShell<R>(
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        let shell = SystemShell(
            environment: environmentVariables.mapValues({ String(describing: $0) }),
            currentDirectoryURL: currentDirectoryURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
            options: [._forwardStdoutStderr]
        )
        
        let result: R = try await operation(shell)
        
        return result
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
            shell.options?.append(._forwardStdoutStderr(to: sink))
            
            return try await operation(shell)
        }
    }
}
