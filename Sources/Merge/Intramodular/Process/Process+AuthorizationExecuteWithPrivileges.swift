//
// Copyright (c) Vatsal Manot
//

#if os(macOS)
import Cocoa
#endif
import Foundation

#if os(macOS)

extension Pipe {
    func _createDarwinFileForReading() -> UnsafeMutablePointer<FILE>? {
        let fileDescriptor = fileHandleForReading.fileDescriptor
        let filePointer = fdopen(fileDescriptor, "r")
        
        return filePointer
    }
}


extension Process {
    private enum LaunchAsRootError: CustomStringConvertible, Error {
        case error(OSStatus)
        
        public var description: String {
            switch self {
                case .error(let status):
                    return status.description
            }
        }
    }
    
    @discardableResult
    public func _launchAsRoot() async throws -> (FileHandle, pid_t) {
        let toolPath = try launchPath!.cString(using: .utf8).unwrap()
        let arguments = (self.arguments ?? []).map { $0.withCString(strdup) }
        
        let standardOutputFilePointer = (self.standardOutput as? Pipe)?.filePointer(mode: "w")
        
        var outputFile = (self.standardOutput as? Pipe)?.filePointer(mode: "w")?.pointee ?? FILE()
        
        return try withUnsafeMutablePointer(to: &outputFile) { outputFilePointer in
            let outputFilePointer = standardOutputFilePointer ?? outputFilePointer
            let executionRights = try withAuthorizationRights(toolPath: toolPath)
            
            let processIdentifier = try executeWithPrivileges(
                authorizationRef: executionRights.authorizationRef,
                toolPath: toolPath,
                arguments: arguments,
                outputFilePointer: outputFilePointer
            )
            
            let outputFileHandle = FileHandle(
                fileDescriptor: fileno(outputFilePointer),
                closeOnDealloc: true
            )
            
            return (outputFileHandle, processIdentifier)
        }
    }
}

extension Process {
    private static var cachedAuthorizationRef: AuthorizationRef?
    
    private func withAuthorizationRights(
        toolPath: UnsafePointer<CChar>
    ) throws -> (authorizationRef: AuthorizationRef?, rights: AuthorizationRights) {
        if let authorizationRef = Process.cachedAuthorizationRef {
            return (authorizationRef, AuthorizationRights())
        }
        
        var authorizationRef: AuthorizationRef?
        var err: OSStatus = noErr
        
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
            
            Process.cachedAuthorizationRef = authorizationRef
            
            return (authorizationRef, myRights)
        }
    }
    
    private func executeWithPrivileges(
        authorizationRef: AuthorizationRef?,
        toolPath: UnsafePointer<CChar>,
        arguments: [UnsafeMutablePointer<CChar>?],
        outputFilePointer: UnsafeMutablePointer<FILE>
    ) throws -> pid_t {
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
        
        var err: OSStatus = noErr
        
        arguments.withUnsafeBufferPointer { arguments in
            err = _AuthorizationExecuteWithPrivileges(
                authorizationRef!,
                toolPath,
                [.interactionAllowed, .extendRights, .preAuthorize],
                arguments.baseAddress,
                outputFilePointer
            )
        }
        
        if err != errAuthorizationSuccess {
            throw LaunchAsRootError.error(err)
        }
        
        let processIdentifier: pid_t = fcntl(fileno(outputFilePointer), F_GETOWN, 0)
        
        return processIdentifier
    }
}

#endif
