//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

/// WIP, not super well thought out.
public protocol _AsyncTaskScheduler {
    func schedule(
        _ task: @Sendable @escaping () async -> Void
    )
    
    func _performCancellable<T: Sendable>(
        @_implicitSelfCapture operation: @Sendable @escaping () async -> T
    ) async -> Result<T, CancellationError>
    
    func perform<T: Sendable>(
        @_implicitSelfCapture operation: @Sendable @escaping () async -> T
    ) async throws -> T
}

// MARK: - Implementation

extension _AsyncTaskScheduler {
    public func _performCancellable<T: Sendable>(
        operation: @escaping @Sendable () async -> T
    ) async -> Result<T, CancellationError> {
        await withUnsafeContinuation { continuation in
            schedule {
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
    
    public func perform<T: Sendable>(
        @_implicitSelfCapture operation: @Sendable @escaping () async -> T
    ) async throws -> T {
        try await _performCancellable(operation: operation).get()
    }
}

// MARK: - Conformees

public struct _DefaultAsyncScheduler {
    public func schedule(
        _ task: @Sendable @escaping () async -> Void
    ) {
        Task {
            await task()
        }
    }
    
    public func perform<T: Sendable>(
        @_implicitSelfCapture operation: @Sendable @escaping () async -> T
    ) async -> Result<T, CancellationError> {
        do {
            let result = await operation()
            
            try Task.checkCancellation()
            
            return .success(result)
        } catch {
            return .failure(CancellationError())
        }
    }
}

extension TaskQueue: _AsyncTaskScheduler {
    public func schedule(
        _ task: @Sendable @escaping () async -> Void
    ) {
        addTask {
            await task()
        }
    }
}

extension ThrowingTaskQueue: _AsyncTaskScheduler {
    public func schedule(
        _ task: @Sendable @escaping () async -> Void
    ) {
        addTask {
            await withTaskCancellationHandler {
                await task()
            } onCancel: {
                assertionFailure()
            }
        }
    }
}
