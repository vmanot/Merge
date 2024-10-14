//
// Copyright (c) Vatsal Manot
//

#if os(macOS) || targetEnvironment(macCatalyst)

import Foundation
import Security

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
class _SecAuthorizedProcess: Process, @unchecked Sendable {
    private static var cachedAuthorizationRef: AuthorizationRef? = KeychainManager.shared.retrieveAuthorizationRef(forRight: .execute)
    
    private var _launchPath: String!
    private var _currentDirectoryURL: URL!
    private var _arguments: [String]!
    private var _environment: [String: String]!
    private var _standardInput: Pipe!
    private var _standardOutput: Pipe!
    private var _standardError: Pipe!
    private var _terminationHandler: (@Sendable (Process) -> Void)?
    private var _terminationStatus: Int32?
    private var _isRunning: Bool = false
    
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
    
    override var environment: [String : String]? {
        get {
            _environment
        } set {
            _environment = newValue
        }
    }
    
    override var standardInput: Any? {
        get {
            _standardInput
        } set {
            _standardInput = newValue as? Pipe
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
    
    override var terminationHandler: (@Sendable (Process) -> Void)? {
        get {
            _terminationHandler
        } set {
            _terminationHandler = newValue
        }
    }
    
    override var terminationStatus: Int32 {
        get {
            _terminationStatus ?? super.terminationStatus
        }
    }
    
    override var terminationReason: Process.TerminationReason {
        if let status = _terminationStatus {
            return status == 0 ? .exit : .uncaughtSignal
        } else {
            return super.terminationReason
        }
    }
    
    override var isRunning: Bool {
        get {
            _isRunning
        }
    }
    
    override public func interrupt() {
        runtimeIssue("\(_SecAuthorizedProcess.self) does not support Process.interrupt()")
    }
    
    override public func run() throws {
        precondition(!_isRunning)
        
        try _executeAuthorizedWithPrivileges(executableURL: executableURL.unwrap())
    }
    
    static let _AuthorizationExecuteWithPrivileges = unsafeBitCast(
        dlsym(UnsafeMutableRawPointer(bitPattern: -2), "AuthorizationExecuteWithPrivileges"),
        to: (@convention(c) (
            AuthorizationRef?,
            UnsafePointer<CChar>,
            AuthorizationFlags,
            UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?,
            UnsafeMutablePointer<FILE>?
        ) -> OSStatus).self
    )
            
    private func _authorizationRef() throws -> AuthorizationRef {
        var status: OSStatus = noErr
        var authorizationRef: AuthorizationRef?

        if let cachedAuthRef = _SecAuthorizedProcess.cachedAuthorizationRef {
            authorizationRef = cachedAuthRef
        } else {
            status = AuthorizationCreate(nil, nil, [.preAuthorize], &authorizationRef)
            
            if status != errAuthorizationSuccess {
                throw _Error.error(status)
            }
            
            let toolPath = try executableURL!.path.cString(using: .utf8).unwrap()
            let toolPathPtr = malloc(toolPath.count)!
            toolPathPtr.copyMemory(from: toolPath, byteCount: toolPath.count)
            
            var authItem = AuthorizationItem(
                name: _AuthorizationRightName.execute.cString,
                valueLength: toolPath.count,
                value: toolPathPtr,
                flags: 0
            )
            
            try withUnsafeMutablePointer(to: &authItem) { authItem in
                var rights = AuthorizationRights(count: 1, items: authItem)
                
                status = AuthorizationCopyRights(
                    authorizationRef!,
                    &rights,
                    nil,
                    [.extendRights, .preAuthorize, .interactionAllowed],
                    nil
                )
                
                free(toolPathPtr)
                
                if status != errAuthorizationSuccess {
                    AuthorizationFree(authorizationRef!, [])
                    
                    runtimeIssue("Failed to copy authorization rights.")
                    
                    throw _Error.error(status)
                }
                
                try KeychainManager.shared.storeAuthorizationRef(
                    authorizationRef!,
                    forRight: .execute
                )
                
                _SecAuthorizedProcess.cachedAuthorizationRef = authorizationRef
            }
        }
        
        return try authorizationRef.unwrap()
    }
    
    var lastAuthorizationExecuteStatus: OSStatus = noErr
    var outputFilePointer: UnsafeMutablePointer<FILE>?

    private func _executeAuthorizedWithPrivileges(
        executableURL: URL
    ) {
        _isRunning = true
                                
        let toolPath = executableURL.path.cString(using: .utf8)!
        
        self.outputFilePointer = _standardOutput.filePointer(mode: "w")
        
        let isUsingCachedAuthorization = Self.cachedAuthorizationRef != nil
        
        @Sendable
        func execute() throws {
            let authorization: AuthorizationRef = try _authorizationRef()
            var arguments: [UnsafeMutablePointer<CChar>?] = (self.arguments ?? []).map { strdup($0) }
           
            arguments.append(nil)

            self.lastAuthorizationExecuteStatus = Self._AuthorizationExecuteWithPrivileges(
                authorization,
                toolPath,
                AuthorizationFlags(rawValue: 0),
                &arguments,
                outputFilePointer
            )
        }
        
        do {
            try execute()
            
            if self.lastAuthorizationExecuteStatus == -60002, isUsingCachedAuthorization {
                Self.cachedAuthorizationRef = nil
                
                try execute()
                
                if self.lastAuthorizationExecuteStatus == errAuthorizationSuccess {
                    runtimeIssue("Cached authorization was invalid.")
                }
            }
        } catch {
            self.lastAuthorizationExecuteStatus = .init(-1)
        }
        
        _isRunning = false

        _exit()
    }
    
    private func _exit() {
        self.willChangeValue(for: \.terminationStatus)
        
        if self.lastAuthorizationExecuteStatus != errAuthorizationSuccess {
            _terminationStatus = Int32(self.lastAuthorizationExecuteStatus)
            
            self.didChangeValue(for: \.terminationStatus)
        } else {
            _terminationStatus = 0
            
            self.didChangeValue(for: \.terminationStatus)
        }
        
        try? _standardOutput.fileHandleForWriting.write(contentsOf: " ".data(using: .utf8)!)

        fclose(outputFilePointer)
        
        _terminationHandler?(self)
    }
    
    override public func waitUntilExit() {
        while isRunning {
            Thread.sleep(forTimeInterval: 0.1)
        }
    }

    private func clearCachedAuthorizationRef() {
        if let authorizationRef = _SecAuthorizedProcess.cachedAuthorizationRef {
            AuthorizationFree(authorizationRef, [])
            _SecAuthorizedProcess.cachedAuthorizationRef = nil
        }
    }
}

@available(macCatalyst, unavailable)
extension _SecAuthorizedProcess {
    fileprivate class KeychainManager {
        static let shared = KeychainManager()
        
        private let bundleIdentifier: String
        
        private init() {
            bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.default.authorizationref"
        }
        
        func storeAuthorizationRef(
            _ authorizationRef: AuthorizationRef,
            forRight right: _AuthorizationRightName
        ) throws {
            var authorizationRef = authorizationRef
            
            let authorizationRefData = Data(
                bytes: &authorizationRef,
                count: MemoryLayout<AuthorizationRef>.size
            )
            
            let queryDictionary: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "AuthorizationRef",
                kSecAttrService as String: "\(bundleIdentifier).\(right)",
                kSecValueData as String: authorizationRefData
            ]
            
            let status = SecItemAdd(queryDictionary as CFDictionary, nil)
            if status == errSecDuplicateItem {
                try updateAuthorizationRef(authorizationRef, forRight: right)
            } else if status != errSecSuccess {
                throw _Error.error(status)
            }
        }
        
        fileprivate func retrieveAuthorizationRef(
            forRight right: _AuthorizationRightName
        ) -> AuthorizationRef? {
            let queryDictionary: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "AuthorizationRef",
                kSecAttrService as String: "\(bundleIdentifier).\(right.rawValue)",
                kSecReturnData as String: true
            ]
            
            var result: AnyObject?
            let status = SecItemCopyMatching(queryDictionary as CFDictionary, &result)
            
            if status == errSecSuccess {
                if let authorizationRefData = result as? Data,
                   authorizationRefData.count == MemoryLayout<AuthorizationRef>.size {
                    let authorizationRef = authorizationRefData.withUnsafeBytes { $0.load(as: AuthorizationRef.self) }
                    return authorizationRef
                }
            }
            
            return nil
        }
        
        fileprivate func updateAuthorizationRef(
            _ authorizationRef: AuthorizationRef,
            forRight right: _AuthorizationRightName
        ) throws {
            var authorizationRef = authorizationRef
            
            let authorizationRefData = Data(bytes: &authorizationRef, count: MemoryLayout<AuthorizationRef>.size)
            
            let queryDictionary: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "AuthorizationRef",
                kSecAttrService as String: "\(bundleIdentifier).\(right.rawValue)"
            ]
            
            let updateDictionary: [String: Any] = [
                kSecValueData as String: authorizationRefData
            ]
            
            let status = SecItemUpdate(queryDictionary as CFDictionary, updateDictionary as CFDictionary)
            if status != errSecSuccess {
                throw _Error.error(status)
            }
        }
        
        func deleteAuthorizationRef(forRight right: String) {
            let queryDictionary: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "AuthorizationRef",
                kSecAttrService as String: "\(bundleIdentifier).\(right)"
            ]
            
            SecItemDelete(queryDictionary as CFDictionary)
        }
    }
}

// MARK: - Auxiliary

fileprivate enum _AuthorizationRightName: String, CaseIterable {
    case execute
    
    var rawValue: String {
        switch self {
            case .execute:
                kAuthorizationRightExecute
        }
    }
    
    static var cStringMapping: [Self: UnsafeMutablePointer<CChar>] = {
        var mapping: [Self: UnsafeMutablePointer<CChar>] = [:]
        for right in Self.allCases {
            mapping[right] = strdup(right.rawValue)
        }
        return mapping
    }()
    
    var cString: UnsafeMutablePointer<CChar> {
        return Self.cStringMapping[self]!
    }
}

// MARK: - Error Handling

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
@available(macCatalyst, unavailable)
extension _SecAuthorizedProcess {
    private enum _Error: CustomStringConvertible, Error {
        case error(OSStatus)
        
        public var description: String {
            switch self {
                case .error(let status):
                    return "Authorization Error: \(status)"
            }
        }
    }
}

fileprivate func withUnsafeMutablePointerAsync<T, ResultType>(
    to initialValue: T,
    perform operation: @escaping (UnsafeMutablePointer<T>) async throws -> ResultType
) async rethrows -> ResultType {
    let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    pointer.initialize(to: initialValue)
    
    do {
        let result = try await operation(pointer)
                
        pointer.deinitialize(count: 1)
        pointer.deallocate()

        return result
    } catch {
        pointer.deinitialize(count: 1)
        pointer.deallocate()

        throw error
    }
}

#endif
