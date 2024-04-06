//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Security
import Swift

class _UnsafePrivilegedProcess: Process {
    private enum LaunchAsRootError: CustomStringConvertible, Error {
        case error(OSStatus)
        
        public var description: String {
            switch self {
                case .error(let status):
                    return status.description
            }
        }
    }
    
    private static var cachedAuthorizationRef: AuthorizationRef?
    
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
        _terminationStatus ?? super.terminationStatus
    }
    
    override var isRunning: Bool {
        _terminationStatus == nil
    }
    
    override var terminationReason: Process.TerminationReason {
        if _terminationStatus == 0 {
            return .exit
        } else {
            return .uncaughtSignal
        }
    }
    
    override public func interrupt() {
        
    }
    
    override public func run() throws {
        let executionRights = try withAuthorizationRights()
        
        func cleanup(error: Error?) throws {
            try _standardOutput.fileHandleForWriting.write(contentsOf: " ".data(using: .utf8)!)
            try _standardError.fileHandleForWriting.write(contentsOf: " ".data(using: .utf8)!)
        }
        
        do {
            try executeWithPrivileges(
                authorizationRef: executionRights.authorizationRef,
                outputFilePointer: _standardOutput.filePointer(mode: "w")!
            )
            
            try cleanup(error: nil)
        } catch {
            try cleanup(error: nil)
            
            throw error
        }
        
        // clearCachedAuthorizationRef()
    }
    
    private func clearCachedAuthorizationRef() {
        if let authorizationRef = _UnsafePrivilegedProcess.cachedAuthorizationRef {
            AuthorizationFree(authorizationRef, [])
            _UnsafePrivilegedProcess.cachedAuthorizationRef = nil
        }
    }
    
    override public func waitUntilExit() {
        super.waitUntilExit()
    }
    
    private func withAuthorizationRights() throws -> (authorizationRef: AuthorizationRef?, rights: AuthorizationRights) {
        if let authorizationRef = _UnsafePrivilegedProcess.cachedAuthorizationRef {
            return (authorizationRef, AuthorizationRights())
        }
        
        var authorizationRef: AuthorizationRef?
        var err: OSStatus = noErr
        
        let toolPath = try! executableURL!.path.cString(using: .utf8).unwrap()
        
        var myItem = withUnsafeMutablePointer(to: &authorizationRef) { authRefPtr in
            toolPath.withUnsafeBytes { toolPathBytes in
                kAuthorizationRightExecute.withCString { name in
                    AuthorizationItem(
                        name: name,
                        valueLength: toolPathBytes.count,
                        value: toolPathBytes.baseAddress?.mutableRepresentation,
                        flags: 0
                    )
                }
            }
        }
        
        return try withUnsafeMutablePointer(to: &myItem) { myItemPointer in
            var myRights = AuthorizationRights(count: 1, items: myItemPointer)
            
            err = AuthorizationCreate(nil, nil, [.preAuthorize], &authorizationRef)
            if err != errAuthorizationSuccess {
                throw LaunchAsRootError.error(err)
            }
            
            err = AuthorizationCopyRights(authorizationRef!, &myRights, nil, [.extendRights, .interactionAllowed], nil)
            if err != errAuthorizationSuccess {
                throw LaunchAsRootError.error(err)
            }
            
            _UnsafePrivilegedProcess.cachedAuthorizationRef = authorizationRef
            
            return (authorizationRef, myRights)
        }
    }
    
    private func executeWithPrivileges(
        authorizationRef: AuthorizationRef?,
        outputFilePointer: UnsafeMutablePointer<FILE>
    ) throws {
        let _AuthorizationExecuteWithPrivileges: @convention(c) (
            AuthorizationRef,
            UnsafePointer<CChar>,
            AuthorizationFlags,
            UnsafePointer<UnsafeMutablePointer<CChar>?>?,
            UnsafeMutablePointer<FILE>?
        ) -> OSStatus
        
        let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)
        
        _AuthorizationExecuteWithPrivileges = unsafeBitCast(
            dlsym(RTLD_DEFAULT, "AuthorizationExecuteWithPrivileges"),
            to: type(of: _AuthorizationExecuteWithPrivileges)
        )
        
        var status: OSStatus = noErr
        
        let toolPath = try executableURL.unwrap().path
        var arguments: [String] = (self.arguments ?? [])
                
        if arguments.first == "-c" {
            arguments[1] = "\"\(arguments[1])\""
        }
        arguments.map({ $0.withCString(strdup) }).withUnsafeBufferPointer { arguments in
            status = _AuthorizationExecuteWithPrivileges(
                authorizationRef!,
                toolPath,
                [],
                arguments.baseAddress,
                outputFilePointer
            )
        }
        
        self.willChangeValue(for: \.terminationStatus)
        
        if let error = ProcessAuthorizationError(status: status) {
            _terminationStatus = status
            
            runtimeIssue(error)
        } else {
            _terminationStatus = 0
        }
        
        self.didChangeValue(for: \.terminationStatus)
    }
}

#endif
