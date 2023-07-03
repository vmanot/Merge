//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

public final class TaskQueue: Sendable {
    public enum Policy: Sendable {
        case cancelPrevious
        case waitOnPrevious
    }
    
    private let queue: _Queue
    
    public init(policy: Policy = .waitOnPrevious) {
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
    ) async -> Result<T, CancellationError> {
        guard _Queue.queueID?.erasedAsAnyHashable != queue.id.erasedAsAnyHashable else {
            if queue.policy == .cancelPrevious {
                await queue.cancelAll()
            }

            return await .success(operation())
        }
                
        return await withUnsafeContinuation { continuation in
            add {
                do {
                    try Task.checkCancellation()
                    
                    continuation.resume(returning: Result<T, CancellationError>.success(await operation()))
                    
                    try Task.checkCancellation()
                } catch {
                    continuation.resume(returning: Result<T, CancellationError>.failure(CancellationError()))
                }
            }
        }
    }
    
    public func perform(
        @_implicitSelfCapture operation: @Sendable @escaping () async -> Void,
        onCancel: @Sendable () -> Void
    ) async {
        let result = await perform(operation: operation)
        
        switch result {
            case .success:
                return
            case .failure:
                onCancel()
        }
    }
        
    public func cancelAll() {
        Task {
            await queue.cancelAll() // FIXME?
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
        
        func cancelAll() {
            previousTask?.cancel()
            previousTask = nil
        }
        
        func add<T: Sendable>(
            _ action: @Sendable @escaping () async -> T
        ) -> Task<Result<T, CancellationError>, Never> {
            guard Self.queueID?.erasedAsAnyHashable != id.erasedAsAnyHashable else {
                fatalError()
            }
            
            if policy == .cancelPrevious {
                cancelAll()
            }
            
            let policy = self.policy
            let previousTask = self.previousTask
            
            let newTask = Task { () async -> Result<T, CancellationError> in
                if let previousTask = previousTask {
                    if policy == .cancelPrevious {
                        previousTask.cancel()
                    }
                    
                    do {
                        _ = try await previousTask.value
                    } catch {
                        return .failure(CancellationError()) // this assumes error is a cancellation error
                    }
                }
                
                do {
                    try Task.checkCancellation()
                } catch {
                    return .failure(CancellationError())
                }
                
                return await Self.$queueID.withValue(id) {
                    await .success(action())
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
