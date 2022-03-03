//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

public actor AsyncTaskQueue: Sendable {
    public enum Policy: Sendable {
        case cancelPreviousAction
        case waitOnPreviousAction
    }
    
    private let policy: Policy
    private var previousTask: OpaqueTask? = nil
    
    public init(policy: Policy = .waitOnPreviousAction) {
        self.policy = policy
    }
    
    /// Performs an action right after the previous action has been finished.
    ///
    /// This ensures that  one action after the other can be executed on ``AsyncTaskQueue``.
    /// If `policy` is set to `.cancelPreviousAction`, then the previous action will be cancelled before the new action is started.
    ///
    /// - parameters:
    ///   - action: Asynchronous function that should be executed. The function may throw and return a value.
    /// - throws: The error thrown by `action`. Especially throws `CancellationError` if the parent task has been cancelled.
    /// - returns: The return value of `action`
    public func perform<T: Sendable>(
        action: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        let newTask = Task { [policy, previousTask] () async throws -> T in
            if policy == .cancelPreviousAction {
                previousTask?.cancel()
            }
            
            _ = try? await previousTask?.value
            
            try Task.checkCancellation()
            
            return try await action()
        }
        
        self.previousTask = OpaqueTask(erasing: newTask)
        
        return try await withTaskCancellationHandler {
            try await newTask.value
        } onCancel: {
            newTask.cancel()
        }
    }
    
    nonisolated public func queue<T: Sendable>(
        _ action: @Sendable @escaping () async throws -> T
    ) {
        Task {
            try await perform {
                try await action()
            }
        }
    }
}
