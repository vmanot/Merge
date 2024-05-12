//
// Copyright (c) Vatsal Manot
//

import Swallow

/// An asynchronous semaphore that limits access to a resource to a specified number of concurrent operations.
///
/// This class provides mechanisms to coordinate the access to a shared resource by multiple asynchronous tasks.
/// This implementation is safe to use in concurrent environments due to its actor-based isolation.
public actor _AsyncActorSemaphore: Sendable {
    fileprivate let limit: Int
    fileprivate var count = 0
    fileprivate var suspensions = [UnsafeContinuation<Void, Never>]()
    
    /// Initializes a new semaphore with a limit on the number of concurrent access allowed.
    /// - Parameter limit: The maximum number of concurrent tasks allowed. Must be greater than zero.
    public init(limit: Int = 1) {
        precondition(limit > 0)
        
        self.limit = limit
    }
    
    /// Asynchronously waits to enter the semaphore.
    ///
    /// If the current count is below the limit, the method increments the count and proceeds.
    /// Otherwise, it suspends the calling task until the semaphore count is decremented by a call to `signal()`.
    public func wait() async {
        if count < limit {
            count += 1
        } else {
            return await withUnsafeContinuation { continuation in
                suspensions.append(continuation)
            }
        }
    }
    
    /// Asynchronously waits to enter the semaphore or fails if the limit is reached.
    ///
    /// Throws an error if the semaphore limit is already reached.
    public func waitOrFail() async throws {
        if count < limit {
            count += 1
        } else {
            throw _PlaceholderError()
        }
    }
    
    /// Signals that a task has completed its use of the semaphore.
    ///
    /// If there are tasks waiting for the semaphore, the first suspended task will be resumed.
    /// If no tasks are waiting, this simply decrements the semaphore count.
    public func signal() {
        precondition(count > 0)
        
        if suspensions.isEmpty {
            count -= 1
        } else {
            suspensions.removeFirst().resume()
        }
    }
    
    /// Signals that a task has completed its use of the semaphore or throws if no tasks are waiting.
    ///
    /// Throws an error if there are no tasks to signal.
    public func signalOrFail() throws {
        guard count > 0 else {
            throw _PlaceholderError()
        }
        
        signal()
    }
    
    /// Executes a block of code within a critical scope by waiting for and then signaling the semaphore.
    ///
    /// This method ensures that the block is run only when the semaphore is successfully acquired.
    /// - Parameter block: A closure that is executed within the critical section.
    /// - Returns: The result of the `block` executed.
    public func withCriticalScope<T>(
        _ block: @Sendable () async -> T
    ) async -> T {
        await wait()
        
        defer {
            signal()
        }
        
        return await block()
    }
    
    /// Executes a block of code that can throw an error within a critical scope by waiting for and then signaling the semaphore.
    ///
    /// This method ensures that the block is run only when the semaphore is successfully acquired.
    /// - Parameter block: A closure that is executed within the critical section and may throw an error.
    /// - Returns: The result of the `block` executed.
    /// - Throws: Rethrows any errors thrown by the `block`.
    @_disfavoredOverload
    public func withCriticalScope<T>(
        _ block: @Sendable () async throws -> T
    ) async rethrows -> T {
        await wait()
        
        do {
            let result: T = try await block()
            
            signal()
            
            return result
        } catch {
            signal()
            
            throw error
        }
    }
}

extension _AsyncActorSemaphore {
    /// A lock that provides mutually exclusive access to a resource.
    ///
    /// This class represents a semaphore with a limit of one, effectively making it a lock.
    public final class Lock: Sendable {
        private enum _Error: Swift.Error {
            case failedToAcquireLock
        }
        
        private let base = _AsyncActorSemaphore(limit: 1)
        
        /// Checks if the lock has been acquired.
        ///
        /// - Returns: A Boolean value indicating whether the lock is currently acquired.
        public var hasBeenAcquired: Bool {
            get async {
                await base.count == 1
            }
        }
        
        /// Initializes a new lock.
        public init() {
            
        }
        
        /// Acquires the lock.
        ///
        /// Suspends the task until the lock can be acquired.
        public func acquire() async {
            await base.wait()
        }
        
        /// Attempts to acquire the lock or fails if it is already acquired.
        ///
        /// Throws an error if the lock cannot be acquired because it is already in use.
        public func acquireOrFail() async throws {
            try await base.waitOrFail()
        }
        
        /// Relinquishes the lock.
        ///
        /// Signals that the task has finished using the resources protected by the lock.
        public func relinquish() async {
            await base.signal()
        }
    }
}
