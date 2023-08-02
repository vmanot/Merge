//
// Copyright (c) Vatsal Manot
//

import Darwin
import Swallow

/// An `os_unfair_lock` wrapper.
public final class OSUnfairLock: Initiable, Sendable, TestableLock {
    @usableFromInline
    let base: os_unfair_lock_t
    
    @inlinable
    public init() {
        let base = os_unfair_lock_t.allocate(capacity: 1)
        
        base.initialize(repeating: os_unfair_lock_s(), count: 1)

        self.base = base
    }

    @inlinable
    public func acquireOrBlock() {
        os_unfair_lock_lock(base)
    }
    
    @inlinable
    public func acquireOrFail() throws {
        let didAcquire = os_unfair_lock_trylock(base)
        
        if !didAcquire {
            throw AcquisitionError.failedToAcquireLock
        }
    }

    @inlinable
    public func relinquish() {
        os_unfair_lock_unlock(base)
    }
    
    deinit {
        base.deinitialize(count: 1)
        base.deallocate()
    }
}

extension OSUnfairLock {
    @discardableResult
    @inlinable
    @inline(__always)
    public func withCriticalScope<Result>(
        perform action: () -> Result
    ) -> Result {
        defer {
            relinquish()
        }
        
        acquireOrBlock()
        
        return action()
    }
}

// MARK: - Error Handling

extension OSUnfairLock {
    @usableFromInline
    enum AcquisitionError: Error {
        case failedToAcquireLock
    }
}
