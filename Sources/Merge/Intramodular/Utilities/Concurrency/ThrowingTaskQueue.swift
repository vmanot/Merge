//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

public final class ThrowingTaskQueue: @unchecked Sendable {
    @_OSUnfairLocked
    public var _unsafeFlags: Set<_UnsafeFlag> = []
    @_OSUnfairLocked
    public var _unsafeStateFlags: Set<_UnsafeStateFlag> = []
    
    private weak var owner: AnyObject?
    private let queue: _TaskQueueActor
    
    /// Returns whether there are tasks currently executing.
    public nonisolated var isActive: Bool {
        queue.hasActiveTasks
    }
    
    public init(policy: TaskQueuePolicy = .waitOnPrevious) {
        self.owner = nil
        self.queue = .init(policy: policy)
    }
    
    public init<Owner: AnyObject>(owner: Owner, policy: TaskQueuePolicy = .waitOnPrevious) {
        self.owner = owner
        self.queue = .init(policy: policy)
    }
    
    /// Spawns a task to add an action to perform.
    ///
    /// This method can be called from a synchronous context.
    ///
    /// - Parameters:
    ///   - action: An async function to execute.
    public func addTask<T: Sendable>(
        priority: TaskPriority? = nil,
        @_implicitSelfCapture operation: @Sendable @escaping () async throws -> T
    ) {
        Task {
            await queue.addTask(priority: priority, operation: operation)
        }
    }
    
    /// Performs an action right after the previous action has been finished.
    ///
    /// - Parameters:
    ///   - action: An async function to execute. The function may throw and return a value.
    /// - Throws: The error thrown by `action`. Especially throws `CancellationError` if the parent task has been cancelled.
    /// - Returns: The return value of `action`
    public func perform<T: Sendable>(
        priority: TaskPriority? = nil,
        @_implicitSelfCapture operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        if queue.policy == .cancelPrevious {
            await queue.cancelAll()
        }
        
        if queue.isReentrantScope {
            return try await _withOwnershipScope {
                try await operation()
            }
        }
        
        if _unsafeFlags.contains(.sanityCheck) {
            assert(!_unsafeStateFlags.contains(.isWithinPerformTaskMethodBody))
        }
        
        let semaphore = _AsyncActorSemaphore()
        let resultBox = _UncheckedSendable(ReferenceBox<Result<T, AnyError>?>(nil))
        
        await semaphore.wait()
        
        _unsafeStateFlags.insert(.isWithinPerformTaskMethodBody)
        
        addTask(priority: priority) {
            do {
                let result = try await _withOwnershipScope {
                    try await operation()
                }
                
                resultBox.wrappedValue.wrappedValue = .success(result)
            } catch {
                resultBox.wrappedValue.wrappedValue = .failure(.init(erasing: error))
            }
            
            await semaphore.signal()
        }
        
        _unsafeStateFlags.remove(.isWithinPerformTaskMethodBody)
        
        let result: T = try await semaphore.withCriticalScope {
            return try resultBox.wrappedValue.wrappedValue!.get()
        }
        
        return result
    }
    
    public func cancelAll() async {
        await queue.cancelAll()
    }
    
    public func cancelAll() {
        Task {
            await self.cancelAll()
        }
    }
    
    public func waitForAll() async throws {
        try await queue.waitForAll()
    }
    
    private func _withOwnershipScope<T>(
        _ block: @Sendable () async throws -> T
    ) async throws -> T {
        try await withDependencies(from: owner) {
            try await block()
        }
    }
}

extension ThrowingTaskQueue {
    public enum _UnsafeFlag {
        case sanityCheck
    }
    
    public enum _UnsafeStateFlag {
        case isWithinPerformTaskMethodBody
    }
}
