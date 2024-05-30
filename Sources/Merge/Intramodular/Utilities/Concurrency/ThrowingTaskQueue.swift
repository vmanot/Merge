//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

public final class ThrowingTaskQueue: @unchecked Sendable {
    public enum _UnsafeFlag {
        case sanityCheck
    }
    
    public enum _UnsafeStateFlag {
        case isWithinPerformTaskMethodBody
    }
    
    public enum Policy: Sendable {
        case cancelPrevious
        case waitOnPrevious
    }
    
    @_OSUnfairLocked
    public var _unsafeFlags: Set<_UnsafeFlag> = []
    @_OSUnfairLocked
    public var _unsafeStateFlags: Set<_UnsafeStateFlag> = []
    
    private weak var owner: AnyObject?
    private let queue: _Queue
    
    public init(policy: Policy = .waitOnPrevious) {
        self.owner = nil
        self.queue = .init(policy: policy)
    }
    
    public init<Owner: AnyObject>(owner: Owner, policy: Policy = .waitOnPrevious) {
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
        
        if _Queue.queueID?.erasedAsAnyHashable == queue.id.erasedAsAnyHashable {
            return try await withOwnershipScope {
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
                let result = try await withOwnershipScope {
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
    
    private func withOwnershipScope<T>(
        _ block: @Sendable () async throws -> T
    ) async throws -> T {
        try await withDependencies(from: owner) {
            try await _Queue.$queueID.withValue(queue.id) {
                try await block()
            }
        }
    }
}

extension ThrowingTaskQueue {
    fileprivate actor _Queue: Sendable {
        let id: (any Hashable & Sendable) = UUID()
        
        let policy: Policy
        var previousTaskBox: ReferenceBox<OpaqueThrowingTask?> = nil
        
        init(policy: Policy) {
            self.policy = policy
        }
        
        func cancelAll() {
            previousTaskBox.wrappedValue?.cancel()
            previousTaskBox.wrappedValue = nil
        }
        
        func addTask<T: Sendable>(
            priority: TaskPriority?,
            operation: @Sendable @escaping () async throws -> T
        ) -> Task<T, Error> {
            guard Self.queueID?.erasedAsAnyHashable != id.erasedAsAnyHashable else {
                fatalError()
            }
            
            let previousTask = self.previousTaskBox.wrappedValue
            
            let newTask = Task(priority: priority) { () async throws -> T in
                await self._waitForPreviousTask(previousTask)
                
                return try await Self.$queueID.withValue(self.id) {
                    try await operation()
                }
            }
            
            self.previousTaskBox.wrappedValue = OpaqueThrowingTask(erasing: newTask)
            
            return newTask
        }
        
        private func _waitForPreviousTask(_ previousTask: OpaqueThrowingTask?) async {
            guard let previousTask else {
                return
            }
            
            let policy = self.policy
            
            if policy == .cancelPrevious {
                previousTask.cancel()
            }
            
            _ = await Result(catching: {
                try await Self.$queueID.withValue(self.id) {
                    try await previousTask.value
                }
            })
        }
        
        func waitForAll() async throws {
            _ = try await previousTaskBox.wrappedValue?.value
        }
    }
}

extension ThrowingTaskQueue._Queue {
    @TaskLocal
    fileprivate static var queueID: (any Hashable & Sendable)?
}
