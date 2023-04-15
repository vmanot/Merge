//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

public final class TaskQueue: Sendable {
    public enum Policy: Sendable {
        case cancelPreviousAction
        case waitOnPreviousAction
    }
    
    private let queue: _Queue
    
    public init(policy: Policy = .waitOnPreviousAction) {
        self.queue = .init(policy: policy)
    }
    
    /// Spawns a task to add an action to perform.
    ///
    /// This method can be called from a synchronous context.
    ///
    /// - Parameters:
    ///   - action: An async function to execute.
    public func add<T: Sendable>(
        @_implicitSelfCapture _ action: @Sendable @escaping () async -> T
    ) {
        Task {
            await queue.add(action)
        }
    }
    
    /// Performs an action right after the previous action has been finished.
    ///
    /// - Parameters:
    ///   - action: An async function to execute. The function may throw and return a value.
    /// - Returns: The return value of `action`
    public func perform<T: Sendable>(
        @_implicitSelfCapture operation: @Sendable @escaping () async -> T
    ) async -> T {
        if queue.policy == .cancelPreviousAction {
            await queue.cancelAllTasks()
        }
        
        guard _Queue.queueID?.erasedAsAnyHashable != queue.id.erasedAsAnyHashable else {
            return await operation()
        }
        
        let semaphore = _AsyncActorSemaphore()
        
        let resultBox = _UncheckedSendable(ReferenceBox<T?>(nil))
        
        await semaphore.wait()
        
        add {
            resultBox.wrappedValue.wrappedValue = await operation()

            await semaphore.signal()
        }
        
        return await semaphore.withCriticalScope {
            return resultBox.wrappedValue.wrappedValue!
        }
    }
    
    public func cancelAll() async {
        await queue.cancelAllTasks()
    }
    
    public func cancelAll() {
        Task {
            await self.cancelAll()
        }
    }
}

extension TaskQueue {
    fileprivate actor _Queue: Sendable {
        let id: (any Hashable & Sendable) = UUID()
        
        let policy: Policy
        var previousTask: OpaqueTask? = nil
        
        init(policy: Policy) {
            self.policy = policy
        }
        
        func cancelAllTasks() {
            previousTask?.cancel()
            previousTask = nil
        }
        
        func add<T: Sendable>(
            _ action: @Sendable @escaping () async -> T
        ) -> Task<T, Never> {
            guard Self.queueID?.erasedAsAnyHashable != id.erasedAsAnyHashable else {
                fatalError()
            }
            
            let policy = self.policy
            let previousTask = self.previousTask
            
            let newTask = Task { () async -> T in
                if let previousTask = previousTask {
                    if policy == .cancelPreviousAction {
                        previousTask.cancel()
                    }
                    
                    _ = try? await previousTask.value
                }
                
                try! Task.checkCancellation()
                
                return await Self.$queueID.withValue(id) {
                    await action()
                }
            }
            
            self.previousTask = OpaqueTask(erasing: newTask)
            
            return newTask
        }
    }
}

extension TaskQueue._Queue {
    @TaskLocal
    fileprivate static var queueID: (any Hashable & Sendable)?
}
