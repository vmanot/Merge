//
// Copyright (c) Vatsal Manot
//

import Combine
import FoundationX
import Swallow

public final class TaskQueue: Sendable {
    private let queue: _Queue
    
    public init() {
        self.queue = .init()
    }
    
    /// Spawns a task to add an action to perform.
    ///
    /// This method can be called from a synchronous context.
    ///
    /// - Parameters:
    ///   - action: An async function to execute.
    public func addTask<T: Sendable>(
        priority: TaskPriority? = nil,
        @_implicitSelfCapture operation: @Sendable @escaping () async -> T
    ) {
        Task {
            await queue.addTask(priority: priority, operation: operation)
        }
    }
    
    @available(*, deprecated, renamed: "addTask")
    public func add<T: Sendable>(
        @_implicitSelfCapture _ operation: @Sendable @escaping () async -> T
    ) {
        addTask(operation: operation)
    }

    /// Performs an action right after the previous action has been finished.
    ///
    /// - Parameters:
    ///   - action: An async function to execute. The function may throw and return a value.
    /// - Returns: The return value of `action`
    public func perform<T: Sendable>(
        @_implicitSelfCapture operation: @Sendable @escaping () async -> T
    ) async -> T {
        guard _Queue.queueID?.erasedAsAnyHashable != queue.id.erasedAsAnyHashable else {
            return await operation()
        }
        
        return await withUnsafeContinuation { continuation in
            addTask {
                continuation.resume(returning: await operation())
            }
        }
    }
    
    public func perform(
        @_implicitSelfCapture operation: @Sendable @escaping () async -> Void,
        onCancel: @Sendable () -> Void
    ) async {
        await perform(operation: operation)
    }
    
    public func cancelAll() {
        Task {
            await queue.cancelAll() // FIXME?
        }
    }
    
    public func waitForAll() async {
        await queue.waitForAll()
    }
}

extension TaskQueue {
    fileprivate actor _Queue: Sendable {
        let id: (any Hashable & Sendable) = UUID()
        
        var previousTask: OpaqueTask? = nil
        
        init() {

        }
        
        func cancelAll() {
            previousTask?.cancel()
            previousTask = nil
        }
        
        func addTask<T: Sendable>(
            priority: TaskPriority?,
            operation: @Sendable @escaping () async -> T
        ) -> Task<T, Never> {
            guard Self.queueID?.erasedAsAnyHashable != id.erasedAsAnyHashable else {
                fatalError()
            }
            
            let previousTask = self.previousTask
            
            let newTask = Task { () async -> T in
                if let previousTask = previousTask {
                    _ = await previousTask.value
                }
                                
                return await Self.$queueID.withValue(id) {
                    await operation()
                }
            }
            
            self.previousTask = OpaqueTask(erasing: newTask)
            
            return newTask
        }
        
        func waitForAll() async {
            guard let last = previousTask else {
                return
            }
            
            _ = await last.value
        }
    }
}

extension TaskQueue._Queue {
    @TaskLocal
    fileprivate static var queueID: (any Hashable & Sendable)?
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
