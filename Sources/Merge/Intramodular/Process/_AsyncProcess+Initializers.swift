//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Foundation
@_spi(Internal) import Swallow
import System

// MARK: - Initializers

#if os(macOS) || targetEnvironment(macCatalyst)
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension _AsyncProcess {
    public convenience init(
        executableURL: URL?,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environmentVariables: [String: String] = [:],
        options: [_AsyncProcess.Option]?
    ) throws {
        #if os(macOS)
        try self.init(
            existingProcess: nil,
            options: options
        )
        
        self.process.executableURL = executableURL ?? URL(fileURLWithPath: "/bin/zsh")
        self.process.arguments = arguments
        self.process.currentDirectoryURL = currentDirectoryURL?._fromURLToFileURL()
        self.process.environment = environmentVariables
        #else
        fatalError(.unsupported)
        #endif
    }
    
    public convenience init(
        launchPath: String?,
        arguments: [String],
        currentDirectoryURL: URL? = nil,
        environmentVariables: [String: String] = [:],
        options: [_AsyncProcess.Option]?
    ) throws {
        try self.init(
            executableURL: launchPath.map({ URL(fileURLWithPath: $0) }),
            arguments: arguments,
            currentDirectoryURL: currentDirectoryURL,
            environmentVariables: environmentVariables,
            options: options
        )
    }
}
#endif
