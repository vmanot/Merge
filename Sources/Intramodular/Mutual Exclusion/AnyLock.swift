//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public class AnyLock: Lock {
    fileprivate let base: Any
    fileprivate let acquireOrBlockImpl: ((Any) -> (() -> Any))
    fileprivate let relinquishImpl: ((Any) -> (() -> Any))
    
    public init<L: Lock>(_ lock: L) {
        self.base = lock
        
        acquireOrBlockImpl = { L.acquireOrBlock($0 as! L) }
        relinquishImpl = { L.relinquish($0 as! L) }
    }
    
    @discardableResult
    public func acquireOrBlock() -> Any {
        return acquireOrBlockImpl(base)()
    }
    
    @discardableResult
    public func relinquish() -> Any {
        return relinquishImpl(base)()
    }
}

public final class AnyTestableLock: AnyLock {
    private let hasBeenAcquiredImpl: ((Any) -> (() -> Bool))
    private let acquireOrFailImpl: ((Any) -> (() throws -> Any))
    
    public init<L: TestableLock>(testable lock: L) {
        hasBeenAcquiredImpl = { lock in { (lock as! L).hasBeenAcquired }}
        acquireOrFailImpl = { L.acquireOrFail($0 as! L) }
        
        super.init(lock)
    }
    
    public var hasBeenAcquired: Bool {
        return hasBeenAcquiredImpl(base)()
    }
    
    @discardableResult
    public func acquireOrFail() throws -> Any {
        return try acquireOrFailImpl(base)()
    }
}

// MARK: - Helpers -

extension AnyLock {    
    public static var osUnfair: AnyLock {
        return .init(OSUnfairLock())
    }
    
    public static var foundation: AnyLock {
        return .init(NSLock())
    }
    
    public static var foundationRecursive: AnyLock {
        return .init(NSRecursiveLock())
    }
}
