//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swift

class _OSAScriptProcess: Process {
    var _launchPath: String!
    var _currentDirectoryURL: URL!
    var _arguments: [String]!
    var _environment: [String: String]!
    var _standardOutput: Pipe!
    var _standardError: Pipe!
    var _terminationStatus: Int32?
    
    override var launchPath: String? {
        get {
            _launchPath
        } set {
            _launchPath = newValue
        }
    }
    
    override var currentDirectoryURL: URL? {
        get {
            _currentDirectoryURL
        } set {
            _currentDirectoryURL = newValue
        }
    }
    
    override var arguments: [String]? {
        get {
            _arguments
        } set {
            _arguments = newValue
        }
    }
    
    override var environment: [String : String]?{
        get {
            _environment
        } set {
            _environment = newValue
        }
    }
    
    override var standardOutput: Any? {
        get {
            _standardOutput
        } set {
            _standardOutput = newValue as? Pipe
        }
    }
    
    override var standardError: Any? {
        get {
            _standardError
        } set {
            _standardError = newValue as? Pipe
        }
    }
    
    override var terminationStatus: Int32 {
        task?.terminationStatus ?? super.terminationStatus
    }
    
    var task: Process!
    
    override public func run() throws {
        let toolPath = try executableURL.unwrap().path
        let arguments = (self.arguments ?? []).joined(separator: "' '")
        
        let script = """
        do shell script "'\(toolPath)' '\(arguments)'" with prompt "\(  Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "This application") wants to run \(toolPath) as root" with administrator privileges
        """
        
        self.task = Process()
        
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        task.standardOutput = _standardOutput
        task.standardError = _standardError
        task.environment = _environment
        task.currentDirectoryURL = _currentDirectoryURL

        try task.run()
    }
    
    override func waitUntilExit() {
        task.waitUntilExit()
    }
    
    override var isRunning: Bool {
        task.isRunning
    }
    
    override var terminationReason: Process.TerminationReason {
        task.terminationReason
    }
}

#endif
