//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

@objc public protocol NSLockProtocol {
    func lock()
    @objc(tryLock) func `try`() -> Bool
    func unlock()
}

// MARK: - Conformances

extension NSLockProtocol where Self: TestableLock {
    public func acquireOrBlock() {
        lock()
    }

    public func acquireOrFail() throws {
        try `try`().orThrow()
    }

    public func relinquish() {
        unlock()
    }
}

// MARK: - Conformances

extension NSLock: NSLockProtocol {

}

extension NSRecursiveLock: NSLockProtocol {

}
