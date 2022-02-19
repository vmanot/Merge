//
// Copyright (c) Vatsal Manot
//

import Darwin
import Swallow

/// An `os_unfair_lock` wrapper.
public final class OSUnfairLock: Initiable, Sendable, TestableLock {
    private let base: os_unfair_lock_t
    
    public init() {
        base = .allocate(capacity: 1)
        base.initialize(to: os_unfair_lock())
    }
    
    public func acquireOrBlock() {
        os_unfair_lock_lock(base)
    }
    
    public func acquireOrFail() throws {
        try os_unfair_lock_trylock(base).throw(if: ==false)
    }
    
    public func relinquish() {
        os_unfair_lock_unlock(base)
    }
    
    deinit {
        base.deinitialize(count: 1)
        base.deallocate()
    }
}
