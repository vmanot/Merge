//
// Copyright (c) Vatsal Manot
//

import Swift

/// A type-erased Task.
public struct OpaqueTask: Sendable {
    private let _completion: @Sendable () async throws -> Any
    private let _cancel: @Sendable () -> Void
    
    /// Wait for the task to complete, returning (or throwing) its result.
    public var value: Any {
        get async throws {
            try await _completion()
        }
    }
    
    public init<Success, Failure>(erasing task: Task<Success, Failure>) {
        self._completion = {
            try await task.value
        }
        
        self._cancel = {
            task.cancel()
        }
    }
    
    /// Attempt to cancel the task.
    public func cancel() {
        _cancel()
    }
}
