//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge

open class AnyCommandLineTool {
    public var environmentVariables: [String: any CLT.EnvironmentVariableValue] = [:]
    public var currentDirectoryURL: URL? = nil
    
    public init() {
        
    }
    
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    @available(macCatalyst, unavailable)
    @discardableResult
    open func withUnsafeSystemShell<R>(
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        let shell = SystemShell(
            environment: environmentVariables.mapValues({ String(describing: $0) }),
            currentDirectoryURL: currentDirectoryURL,
            options: [._forwardStdoutStderr]
        )
        
        let result: R = try await operation(shell)
        
        return result
    }
}
