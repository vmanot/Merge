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
    
    public var objectIdentifierTree: ObjectIdentifierTree {
        return queue
            .objectIdentifierTree
            .wrapped(by: type(of: self))
    }
    
    public var isUniquelyReferenced: Bool {
        mutating get {
            return isKnownUniquelyReferenced(&queue)
        }
    }
    
    public init(targetQueue: DispatchQueue?) {
        self.queue = DispatchQueue(
            label: "com.vmanot.Merge.DispatchMutexDevice",
            attributes: [.concurrent],
            target: targetQueue
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
    
    public var objectIdentifierTree: ObjectIdentifierTree {
        return queue
            .objectIdentifierTree
            .wrapped(by: type(of: self))
    }
    
    public var isUniquelyReferenced: Bool {
        mutating get {
            return isKnownUniquelyReferenced(&queue)
        }
    }
    
    public init(targetQueue: DispatchQueue?) {
        self.queue = DispatchQueue(
            label: "com.vmanot.Merge.DispatchReentrantMutexDevice",
            attributes: [.concurrent],
            target: targetQueue
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

// MARK: - Protocol Conformances -

extension DispatchMutexDevice: Initiable {
    public init() {
        self.init(targetQueue: nil)
    }
}

extension DispatchReentrantMutexDevice: Initiable {
    public init() {
        self.init(targetQueue: nil)
    }
}
