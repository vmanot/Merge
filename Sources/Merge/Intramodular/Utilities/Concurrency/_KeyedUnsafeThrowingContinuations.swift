//
// Copyright (c) Vatsal Manot
//

import Swift

public actor _KeyedUnsafeThrowingContinuations<Key: Hashable, Value> {
    private var waiters: [Key: [UnsafeContinuation<Value, Swift.Error>]] = [:]
    
    public var keys: Set<Key> {
        Set(waiters.keys)
    }
    
    public init() {
        
    }
    
    public func wait(
        forKey key: Key
    ) async throws -> Value {
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Value, Swift.Error>) in
            self.waiters[key, default: []].insert(continuation)
        }
    }
    
    public func resume(
        forKey key: Key,
        with value: Value
    ) {
        guard let continuations = waiters[key], !continuations.isEmpty else {
            return
        }
        
        for continuation in continuations {
            continuation.resume(returning: value)
        }
        
        waiters[key] = nil
    }
    
    public func cancel(forKey key: Key) {
        guard let continuations = waiters[key], !continuations.isEmpty else {
            return
        }
        
        for continuation in continuations {
            continuation.resume(throwing: CancellationError())
        }
        
        waiters[key] = nil
    }
    
    public func contains(key: Key) -> Bool {
        return waiters[key] != nil
    }
    
    public func cancelAll() {
        waiters.forEach {
            $0.value.forEach { continuation in
                continuation.resume(throwing: CancellationError())
            }
        }
        waiters.removeAll()
    }
    
    public func resumeAll(returning value: Value) {
        waiters.forEach {
            $0.value.forEach { continuation in
                continuation.resume(returning: value)
            }
        }
        waiters.removeAll()
    }
    
    public func resumeAll() where Value == Void {
        resumeAll(returning: ())
    }
}
