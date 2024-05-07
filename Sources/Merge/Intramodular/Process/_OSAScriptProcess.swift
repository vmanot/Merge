//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swift

public class _OSAScriptProcess: Process {
    private var underlyingTask = Process()
    
    override public var launchPath: String? {
        get { underlyingTask.launchPath }
        set { underlyingTask.launchPath = newValue }
    }
    
    override public var currentDirectoryURL: URL? {
        get { underlyingTask.currentDirectoryURL }
        set { underlyingTask.currentDirectoryURL = newValue }
    }
    
    override public var arguments: [String]? {
        get { underlyingTask.arguments }
        set { underlyingTask.arguments = newValue }
    }
    
    override public var environment: [String : String]? {
        get { underlyingTask.environment }
        set { underlyingTask.environment = newValue }
    }
    
    override public var standardOutput: Any? {
        get { underlyingTask.standardOutput }
        set { underlyingTask.standardOutput = newValue }
    }
    
    override public var standardError: Any? {
        get { underlyingTask.standardError }
        set { underlyingTask.standardError = newValue }
    }
    
    override public var terminationStatus: Int32 {
        return underlyingTask.terminationStatus
    }
    
    override public var isRunning: Bool {
        return underlyingTask.isRunning
    }
    
    override public var terminationReason: Process.TerminationReason {
        return underlyingTask.terminationReason
    }
    
    override public func run() throws {
        guard let executablePath = self.executableURL?.path else {
            throw NSError(domain: "OSAScriptProcessError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Executable URL is not set."])
        }
        
        let argumentsEscaped = arguments?
            .map({ $0.replacingOccurrences(of: "'", with: "'\\''") })
            .joined(separator: " ") ?? ""
        
        let script: String = """
        do shell script "'\(executablePath)' \(argumentsEscaped)" with prompt "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "This application") wants to run \(executablePath) as root" with administrator privileges
        """
        
        // Setup the task to run the osascript
        underlyingTask.launchPath = "/usr/bin/osascript"
        underlyingTask.arguments = ["-e", script]
        underlyingTask.standardOutput = standardOutput
        underlyingTask.standardError = standardError
        underlyingTask.environment = environment
        underlyingTask.currentDirectoryURL = currentDirectoryURL
        
        try underlyingTask.run()
    }
    
    override public func waitUntilExit() {
        underlyingTask.waitUntilExit()
    }
}

#endif
