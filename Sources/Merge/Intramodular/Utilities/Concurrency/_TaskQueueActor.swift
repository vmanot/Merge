//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

actor _TaskQueueActor: Sendable {
    let id: (any Hashable & Sendable) = UUID()
    let policy: TaskQueuePolicy
    
    nonisolated let previousTaskBox: _OSUnfairLocked<OpaqueThrowingTask?> = nil
    
    public nonisolated var isReentrantScope: Bool {
        Self.queueID?.erasedAsAnyHashable == id.erasedAsAnyHashable
    }
    
    nonisolated var hasActiveTasks: Bool {
        previousTaskBox.wrappedValue != nil
    }
    
    init(policy: TaskQueuePolicy) {
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
    
    func addTask<T: Sendable>(
        priority: TaskPriority?,
        operation: @Sendable @escaping () async -> T
    ) -> Task<T, Never> {
        guard Self.queueID?.erasedAsAnyHashable != id.erasedAsAnyHashable else {
            fatalError()
        }
        
        let previousTask = self.previousTaskBox.wrappedValue
        
        let newTask = Task(priority: priority) { () async -> T in
            await self._waitForPreviousTask(previousTask)
            
            return await Self.$queueID.withValue(self.id) {
                await operation()
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

extension _TaskQueueActor {
    @TaskLocal
    fileprivate static var queueID: (any Hashable & Sendable)?
}
