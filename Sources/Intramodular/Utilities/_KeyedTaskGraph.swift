//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

/// An actor that can manage a graph of running tasks.
public actor _KeyedTaskGraph<Key: Hashable & Sendable>: Sendable {
    public enum InsertPolicy: Hashable & Sendable {
        case discardPrevious
        case useExisting
        case unspecified
    }
    
    private let tasks = MutexProtected(wrappedValue: [Key: OpaqueTask]())
    
    public init() {
        
    }
    
    public init() where Key == AnyHashable {
        
    }
    
    private func pruneTask(withKey key: Key) {
        tasks.assignedValue.removeValue(forKey: key)
    }
    
    private nonisolated func insertTask<T: Sendable>(
        withKey key: Key,
        priority: TaskPriority? = nil,
        insertionPolicy: InsertPolicy = .unspecified,
        @_implicitSelfCapture operation: @escaping @Sendable () async throws -> T
    ) throws -> Task<T, Error> {
        let existingTask = tasks.assignedValue[key]
        
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
                    
                    tasks.assignedValue[key] = result.eraseToOpaqueTask()
                }
            case .unspecified:
                if existingTask != nil {
                    throw _Error.insertPolicyUnspecified(for: key)
                } else {
                    result = Task.detached(priority: priority) {
                        let result = try await operation()
                        
                        await self.pruneTask(withKey: key)
                        
                        return result
                    }
                    
                    tasks.assignedValue[key] = result.eraseToOpaqueTask()
                }
        }
        
        return result
    }
            
    @discardableResult
    public nonisolated func insert<T: Sendable>(
        _ key: Key,
        priority: TaskPriority? = nil,
        policy: InsertPolicy = .unspecified,
        @_implicitSelfCapture operation: @escaping @Sendable () async throws -> T
    ) throws -> Task<T, Error> {
        try insertTask(
            withKey: key,
            priority: priority,
            insertionPolicy: policy,
            operation: operation
        )
    }
    
    public func perform<T: Sendable>(
        _ key: Key,
        priority: TaskPriority? = nil,
        policy: InsertPolicy = .unspecified,
        @_implicitSelfCapture operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await insertTask(
            withKey: key,
            priority: priority,
            insertionPolicy: policy,
            operation: operation
        ).value
    }
    
    public func wait(on key: Key) async throws {
        _ = try await tasks.assignedValue[key]?.value // TODO: Track as a suspension elswhere
    }
}

extension _KeyedTaskGraph {
    private enum _Error: Swift.Error, Hashable, Sendable {
        case insertPolicyUnspecified(for: Key)
    }
}
