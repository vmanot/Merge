//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

/// WIP, not well-thought out.
public protocol _AsyncScheduler {
    func schedule(
        _ task: @Sendable @escaping () async -> Void
    )
    
    func perform<T: Sendable>(
        @_implicitSelfCapture operation: @Sendable @escaping () async -> T
    ) async -> Result<T, CancellationError>
}

extension _AsyncScheduler {
    public func perform<T>(
        operation: @escaping @Sendable () async -> T
    ) async -> Result<T, CancellationError> where T : Sendable {
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
}

public struct _DefaultAsyncScheduler {
    public func schedule(
        _ task: @Sendable @escaping () async -> Void
    ) {
        
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

extension TaskQueue: _AsyncScheduler {
    public func schedule(
        _ task: @Sendable @escaping () async -> Void
    ) {
        add {
            await task()
        }
    }
}
