//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swift
import SwallowMacrosClient

public class _OSAScriptProcess: Process, @unchecked Sendable {
    private var underlyingTask = Process()
    private var pidFilePath: String = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pid").path
    private var _terminationHandler: (@Sendable (Process) -> Void)?
    
    public var pid: Int32? {
        guard
            let pidString = try? String(contentsOfFile: pidFilePath, encoding: .utf8),
            let pid = Int32(pidString.trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            return nil
        }
        return pid
    }
    
    override public var launchPath: String? {
        get {
            underlyingTask.launchPath
        } set {
            underlyingTask.launchPath = newValue
        }
    }
    
    override public var currentDirectoryURL: URL? {
        get {
            underlyingTask.currentDirectoryURL
        } set {
            underlyingTask.currentDirectoryURL = newValue
        }
    }
    
    override public var arguments: [String]? {
        get {
            underlyingTask.arguments
        } set {
            underlyingTask.arguments = newValue
        }
    }
    
    override public var environment: [String : String]? {
        get {
            underlyingTask.environment
        } set {
            underlyingTask.environment = newValue
        }
    }
    
    override public var standardInput: Any? {
        get {
            underlyingTask.standardInput
        } set {
            underlyingTask.standardInput = newValue
        }
    }
    
    override public var standardOutput: Any? {
        get {
            underlyingTask.standardOutput
        } set {
            underlyingTask.standardOutput = newValue
        }
    }
    
    override public var standardError: Any? {
        get {
            underlyingTask.standardError
        } set {
            underlyingTask.standardError = newValue
        }
    }
    
    override public var terminationStatus: Int32 {
        underlyingTask.terminationStatus
    }
    
    override public var isRunning: Bool {
        underlyingTask.isRunning
    }
    
    override public var terminationReason: Process.TerminationReason {
        underlyingTask.terminationReason
    }
    
    override public var processIdentifier: Int32 {
        underlyingTask.processIdentifier
    }
    
    override public var terminationHandler: (@Sendable (Process) -> Void)? {
        get {
            _terminationHandler
        } set {
            _terminationHandler = newValue
        }
    }
        
    override public func run() throws {
        let (launchPath, arguments) = try _OSAScriptProcess._osascript_launchPathAndArguments(for: (executableURL, arguments))
        
        underlyingTask.launchPath = launchPath
        underlyingTask.arguments = arguments
        underlyingTask.standardOutput = standardOutput
        underlyingTask.standardError = standardError
        underlyingTask.environment = environment
        underlyingTask.currentDirectoryURL = currentDirectoryURL
        
        underlyingTask.terminationHandler = { [weak self] process in
            self?._handleTermination(process)
        }
        
        try underlyingTask.run()
    }
    
    private func _handleTermination(_ process: Process) {
        assert(process === underlyingTask)
        
        self.terminationHandler?(self)
    }
    
    override public func waitUntilExit() {
        underlyingTask.waitUntilExit()
        
        try? FileManager.default.removeItem(atPath: pidFilePath)
    }
    
    deinit {
        try? FileManager.default.removeItem(atPath: pidFilePath)
    }
}

extension _OSAScriptProcess {
    public static func _osascript_launchPathAndArguments(
        for executableURLAndArguments: (executableURL: URL?, arguments: [String]?)
    ) throws -> (launchPath: String, arguments: [String]) {
        guard let executablePath: String = executableURLAndArguments.executableURL?.path else {
            throw NSError(domain: "OSAScriptProcessError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Executable URL is not set."])
        }
        
        let argumentsString: String?
        
        if let arguments = executableURLAndArguments.arguments {
            if arguments.contains(where: { $0.contains("'") }) {
                argumentsString = arguments
                    .map({ $0.replacingOccurrences(of: "'", with: "'\\''") })
                    .joined(separator: " ")
            } else if arguments.first == "-c", arguments.count == 2 {
                let command: String = escaper(arguments.last!)
                
                argumentsString = "-c \\\"\(command)\\\""
            } else {
                throw Never.Reason.unimplemented
            }
        } else {
            argumentsString = nil
        }
        
        let cmdStr = "do shell script \"\(executablePath) \(argumentsString ?? String())\" with administrator privileges"
        
        let launchPath = "/usr/bin/osascript"
        let arguments = ["-e", cmdStr]
        
        return (launchPath, arguments)
    }
    
    /// Thanks to `https://github.com/smittytone/mnu/`!
    static func escaper(
        _ unescapedString: String
    ) -> String {
        
        // FROM 1.3.0
        // Process the user's code string to double-escape
        // For example, if the user enters:
        //      echo "$GIT"
        // then the string is stored as:
        //      echo \"$GIT\"
        // But because this will be inserted into another string (see 'runScript()') within escaped double-quotes,
        // we have to double-escape everything, ie. make the string:
        //      echo \\\"$GIT\\\""
        // osascript then correctly interprets all the escapes
        // See also MNUTests.swift::testEscaper() for more examples
        
        // Convert the script string to an NSString so we can run 'replacingOccurrences()'
        var escapedCode: NSString = unescapedString as NSString
        
        // Look for user-escaped DQs and temporarily hide them
        escapedCode = escapedCode.replacingOccurrences(of: "\\\"", with: "!-USER-ESCAPED-D-QUOTES-!") as NSString
        
        // FROM 1.6.0
        // Process escaped slashes ***
        escapedCode = escapedCode.replacingOccurrences(of: "\\", with: "\\\\") as NSString
        // Look for escaped DQs
        escapedCode = escapedCode.replacingOccurrences(of: "\"", with: "\\\"") as NSString
        
        // FROM 1.6.0
        // Remove specific slash-symbol combos, which should now be covered by *** above
        // Look for escaped $ symbols: \$ -> \\$ -> \\\\$
        //escapedCode = escapedCode.replacingOccurrences(of: "\\$", with: "\\\\$") as NSString
        // Look for escaped ` symbols
        //escapedCode = escapedCode.replacingOccurrences(of: "\\`", with: "\\\\`") as NSString
        
        // Put back user-escaped DQs
        escapedCode = escapedCode.replacingOccurrences(of: "!-USER-ESCAPED-D-QUOTES-!", with: "\\\\\\\"") as NSString
        
        return escapedCode as String
    }
}

#endif
