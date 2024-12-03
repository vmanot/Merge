//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation

extension NSLocking {
    /// Performs `body` with the lock held.
    public func _performWithLock<Result>(
        _ body: () throws -> Result
    ) rethrows -> Result {
        self.lock()
        defer { self.unlock() }
        return try body()
    }
    
    /// Given that the lock is held, **unlocks it**, performs `body`,
    /// then relocks it.
    ///
    /// Be very careful with your thread-safety analysis when using this function!
    public func _performWithoutLock<Result>(
        _ body: () throws -> Result
    ) rethrows -> Result {
        self.unlock()
        defer { self.lock() }
        return try body()
    }
}
