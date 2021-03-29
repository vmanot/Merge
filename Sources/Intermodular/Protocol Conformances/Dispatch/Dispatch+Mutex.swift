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

public struct DispatchMutexDevice: ScopedReadWriteMutex {
    private var queue: DispatchQueue
    
    public var isUniquelyReferenced: Bool {
        mutating get {
            return isKnownUniquelyReferenced(&queue)
        }
    }
    
    public init(label: String? = nil, target: DispatchQueue? = nil) {
        self.queue = DispatchQueue(
            label: label ?? "com.vmanot.Merge.DispatchMutexDevice",
            attributes: [.concurrent],
            target: target
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

public struct DispatchReentrantMutexDevice: ReentrantMutex, ScopedMutex {
    private var queueTagKey = DispatchSpecificKey<Void>()
    private var queue: DispatchQueue
    
    public var isUniquelyReferenced: Bool {
        mutating get {
            return isKnownUniquelyReferenced(&queue)
        }
    }
    
    public init(target: DispatchQueue? = nil) {
        self.queue = DispatchQueue(
            label: "com.vmanot.Merge.DispatchReentrantMutexDevice",
            attributes: [.concurrent],
            target: target
        )
        
        self.queue.setSpecific(key: queueTagKey, value: ())
    }
    
    public func withCriticalScope<T>(_ f: (() throws -> T)) rethrows -> T {
        if DispatchQueue.getSpecific(key: queueTagKey) != nil {
            return try f()
        } else {
            return try queue.sync(flags: .barrier, execute: { try f() })
        }
    }
}

// MARK: - Conformances -

extension DispatchMutexDevice: Initiable {
    public init() {
        self.init(target: nil)
    }
}

extension DispatchReentrantMutexDevice: Initiable {
    public init() {
        self.init(target: nil)
    }
}
