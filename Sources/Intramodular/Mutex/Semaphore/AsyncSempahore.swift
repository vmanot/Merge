//
// Copyright (c) Vatsal Manot
//

import Swallow

public actor _AsyncActorSemaphore: Sendable {
    fileprivate let limit: Int
    fileprivate var count = 0
    fileprivate var suspensions = [UnsafeContinuation<Void, Never>]()
    
    public init(limit: Int = 1) {
        precondition(limit > 0)
        
        self.limit = limit
    }
    
    public func wait() async {
        if count < limit {
            count += 1
        } else {
            return await withUnsafeContinuation { continuation in
                suspensions.append(continuation)
            }
        }
    }
    
    public func waitOrFail() async throws {
        if count < limit {
            count += 1
        } else {
            throw EmptyError()
        }
    }
    
    public func signal() {
        precondition(count > 0)
        
        if suspensions.isEmpty {
            count -= 1
        } else {
            suspensions.removeFirst().resume()
        }
    }
    
    public func signalOrFail() throws {
        guard count > 0 else {
            throw EmptyError()
        }
        
        signal()
    }
    
    public func withCriticalScope<T>(
        _ block: @Sendable () async -> T
    ) async -> T {
        await wait()
        
        defer {
            signal()
        }
        
        return await block()
    }
    
    @_disfavoredOverload
    public func withCriticalScope<T>(
        _ block: @Sendable () async throws -> T
    ) async rethrows -> T {
        await wait()
        
        defer {
            signal()
        }
        
        return try await block()
    }
}

extension _AsyncActorSemaphore {
    public final class Lock: Sendable {
        private enum _Error: Swift.Error {
            case failedToAcquireLock
        }
        
        private let base = _AsyncActorSemaphore(limit: 1)
        
        public var hasBeenAcquired: Bool {
            get async {
                await base.count == 1
            }
        }
        
        public init() {
            
        }
        
        public func acquire() async {
            await base.wait()
        }
        
        public func acquireOrFail() async throws {
            try await base.waitOrFail()
        }
        
        public func relinquish() async {
            await base.signal()
        }
    }
}
