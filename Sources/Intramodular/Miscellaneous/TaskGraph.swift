//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

/// An actor that can manage a graph of running tasks.
public actor TaskGraph<Key: Hashable & Sendable>: Sendable {
    public enum InsertPolicy: Hashable & Sendable {
        case discardPrevious
        case useExisting
    }
    
    private var tasks: [Key: OpaqueTask] = [:]
    
    public init() {
        
    }
    
    public init() where Key == AnyHashable {
        
    }
    
    private func pruneTask(withKey key: Key) {
        tasks.removeValue(forKey: key)
    }
    
    private func insertTask<T: Sendable>(
        withKey key: Key,
        priority: TaskPriority? = nil,
        insertionPolicy: InsertPolicy,
        @_implicitSelfCapture operation: @escaping @Sendable () async throws -> T
    ) -> Task<T, Error> {
        let existingTask = tasks[key]
        
        let result: Task<T, Error>
        
        switch insertionPolicy {
            case .discardPrevious:
                existingTask?.cancel()
                result = Task.detached(priority: priority) {
                    let result = try await operation()
                    
                    await self.pruneTask(withKey: key)
                    
                    return result
                }
            case .useExisting:
                if let existingTask = existingTask {
                    result = Task.detached(priority: priority) {
                        try await cast(existingTask.value, to: T.self)
                    }
                } else {
                    result = Task.detached(priority: priority) {
                        let result = try await operation()
                        
                        await self.pruneTask(withKey: key)
                        
                        return result
                    }
                    
                    tasks[key] = result.eraseToOpaqueTask()
                }
        }
        
        return result
    }
    
    public func insert<T: Sendable>(
        _ key: Key,
        priority: TaskPriority? = nil,
        policy: InsertPolicy,
        @_implicitSelfCapture operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await insertTask(
            withKey: key,
            priority: priority,
            insertionPolicy: policy,
            operation: operation
        ).value
    }
    
    @_disfavoredOverload
    public nonisolated func insert<T: Sendable>(
        _ key: Key,
        priority: TaskPriority? = nil,
        policy: InsertPolicy,
        @_implicitSelfCapture operation: @escaping @Sendable () async throws -> T
    ) {
        Task.detached { [weak self] in
            try await self?.insert(
                key,
                priority: priority,
                policy: policy,
                operation: operation
            )
        }
    }
}
