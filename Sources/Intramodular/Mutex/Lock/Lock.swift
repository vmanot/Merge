//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol Lock: ScopedMutex, Sendable {
    func acquireOrBlock()
    func relinquish()
}

public protocol TestableLock: Lock, TestableScopedMutex {
    var hasBeenAcquired: Bool { get }
    
    func acquireOrFail() throws
}

public protocol ReentrantLock: Lock, ReentrantMutex {
    
}

// MARK: - Implementation

extension Lock {
    @discardableResult
    @inlinable
    public func withCriticalScope<T>(_ f: (() throws -> T)) rethrows -> T {
        defer {
            relinquish()
        }
        acquireOrBlock()
        return try f()
    }
}

extension TestableLock {
    public var hasBeenAcquired: Bool {
        if let _ = try? acquireOrFail() {
            relinquish()
            return false
        } else {
            return true
        }
    }
    
    @discardableResult
    public func withCriticalScope<T>(attempt f: (() throws -> T)) rethrows -> T? {
        guard let _ = try? acquireOrFail() else {
            return nil
        }
        defer {
            relinquish()
        }
        return try f()
    }
}

// MARK: - Conformances

public final class AnyLock: Lock {
    public let base: Lock
    
    public init<L: Lock>(_ base: L) {
        self.base = base
    }
    
    public func acquireOrBlock() {
        base.acquireOrBlock()
    }
    
    public func relinquish() {
        base.relinquish()
    }
}
