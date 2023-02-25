//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Swallow

extension DispatchGroup: ScopedMutex {
    public func withCriticalScope<T>(_ f: (() throws -> T)) rethrows -> T {
        enter()
        defer {
            leave()
        }
        return try f()
    }
}

public struct DispatchMutexDevice: ScopedReadWriteMutex, @unchecked Sendable {
    @MutexProtected<DispatchQueue, OSUnfairLock>
    private var queue: DispatchQueue
    
    public init(label: String? = nil, target: DispatchQueue? = nil) {
        self._queue = .init(
            wrappedValue: DispatchQueue(
                label: label ?? "com.vmanot.Merge.DispatchMutexDevice",
                attributes: [.concurrent],
                target: target
            )
        )
    }
    
    public func withCriticalScopeForReading<T>(_ f: (() throws -> T)) rethrows -> T {
        return try queue.sync {
            try f()
        }
    }
    
    public func withCriticalScopeForWriting<T>(_ f: (() throws -> T)) rethrows -> T {
        return try queue.sync(flags: .barrier) {
            try f()
        }
    }
}

// MARK: - Conformances

extension DispatchMutexDevice: Initiable {
    public init() {
        self.init(target: nil)
    }
}
