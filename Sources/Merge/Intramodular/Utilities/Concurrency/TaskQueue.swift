//
// Copyright (c) Vatsal Manot
//

import Combine
import FoundationX
import Swallow

public enum TaskQueuePolicy: Sendable {
    case cancelPrevious
    case waitOnPrevious
}

public final class TaskQueue: Sendable {
    private let queue: _TaskQueueActor
    
    /// Returns whether there are tasks currently executing.
    public nonisolated var isActive: Bool {
        queue.hasActiveTasks
    }
    
    public init() {
        self.queue = .init(policy: .waitOnPrevious)
    }
    
    /// Spawns a task to add an action to perform, with optional debouncing.
    ///
    /// This method can be called from a synchronous context.
    ///
    /// - Parameters:
    ///   - action: An async function to execute.
    ///   - debounceInterval: Minimum time interval to wait after a task before starting the next one.
    public func addTask<T: Sendable>(
        priority: TaskPriority? = nil,
        @_implicitSelfCapture operation: @Sendable @escaping () async -> T
    ) {
        Task {
            await queue.addTask(
                priority: priority,
                operation: operation
            )
        }
    }
    
    /// Performs an action right after the previous action has been finished, with debouncing.
    ///
    /// - Parameters:
    ///   - action: An async function to execute. The function may throw and return a value.
    ///   - debounceInterval: Minimum time interval to wait after a task before starting the next one.
    /// - Returns: The return value of `action`
    public func perform<T: Sendable>(
        @_implicitSelfCapture operation: @Sendable @escaping () async -> T
    ) async -> T {
        if queue.policy == .cancelPrevious {
            await queue.cancelAll()
        }
        
        if queue.isReentrantScope {
            return await operation()
        }
        
        return await withUnsafeContinuation { continuation in
            addTask {
                continuation.resume(returning: await operation())
            }
        }
    }
    
    public func cancelAll() {
        Task {
            await queue.cancelAll()
        }
    }
    
    public func waitForAll() async {
        #try(.optimistic) {
            try await queue.waitForAll()
        }
    }
}

// MARK: - Supplementary

public func withTaskQueue<ChildTaskResult, Result>(
    of childTaskResultType: ChildTaskResult.Type,
    returning returnType: Result.Type = Result.self,
    body: (TaskQueue) async -> Result
) async throws -> Result {
    let queue = TaskQueue()
    
    let result = await body(queue)
    
    await queue.waitForAll()
    
    return result
}

public func withThrowingTaskQueue<ChildTaskResult, Result>(
    of childTaskResultType: ChildTaskResult.Type,
    returning returnType: Result.Type = Result.self,
    body: (ThrowingTaskQueue) async throws -> Result
) async throws -> Result {
    let queue = ThrowingTaskQueue()
    
    let result = await Swift.Result(catching: {
        try await body(queue)
    })
    
    try await queue.waitForAll()
    
    return try result.get()
}
