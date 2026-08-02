//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

/// An actor that can manage a graph of running tasks.
public actor KeyedThrowingTaskGroup<Key: Hashable & Sendable>: Sendable {
    public enum InsertPolicy: Hashable & Sendable {
        case discardPrevious
        case useExisting
        case unspecified
    }
    
    private struct TaskEntry {
        let id: UUID
        let task: OpaqueThrowingTask
    }

    private let tasks = MutexProtected(wrappedValue: [Key: TaskEntry]())
    
    public init() {
        
    }
    
    public init() where Key == AnyHashable {
        
    }
    
    private nonisolated func pruneTask(withKey key: Key, id: UUID) {
        tasks.mutate { tasks in
            guard tasks[key]?.id == id else {
                return
            }
            tasks.removeValue(forKey: key)
        }
    }
    
    private nonisolated func insertTask<T: Sendable>(
        withKey key: Key,
        priority: TaskPriority? = nil,
        insertionPolicy: InsertPolicy = .unspecified,
        @_implicitSelfCapture operation: @escaping @Sendable () async throws -> T
    ) throws -> Task<T, Error> {
        try tasks.mutate { tasks in
            let existingTask: OpaqueThrowingTask? = tasks[key]?.task

            func makeTask() -> (Task<T, Error>, TaskEntry) {
                let id = UUID()
                let task = Task.detached(priority: priority) {
                    defer {
                        self.pruneTask(withKey: key, id: id)
                    }
                    return try await operation()
                }
                return (
                    task,
                    TaskEntry(id: id, task: task.eraseToOpaqueThrowingTask())
                )
            }

            switch insertionPolicy {
            case .discardPrevious:
                existingTask?.cancel()
                let (task, entry) = makeTask()
                tasks[key] = entry
                return task
            case .useExisting:
                if let existingTask = existingTask {
                    return Task.detached(priority: priority) {
                        try await cast(existingTask.value, to: T.self)
                    }
                } else {
                    let (task, entry) = makeTask()
                    tasks[key] = entry
                    return task
                }
            case .unspecified:
                if existingTask != nil {
                    throw _Error.insertPolicyUnspecified(for: key)
                } else {
                    let (task, entry) = makeTask()
                    tasks[key] = entry
                    return task
                }
            }
        }
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
        let task: OpaqueThrowingTask? = tasks.withCriticalScope { $0[key]?.task }
        _ = try await task?.value  // TODO: Track as a suspension elswhere
    }
}

extension KeyedThrowingTaskGroup {
    private enum _Error: Swift.Error, Hashable, Sendable {
        case insertPolicyUnspecified(for: Key)
    }
}
