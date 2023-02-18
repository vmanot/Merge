//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift

extension Task {
    public static func firstResult<R: Sendable>(
        from tasks: [(@Sendable () async throws -> R)]
    ) async throws -> R? {
        return try await withThrowingTaskGroup(of: R.self) { group in
            for task in tasks {
                group.addTask {
                    try await task()
                }
            }
            // First finished child task wins, cancel the other task.
            let result = try await group.next()
            
            group.cancelAll()
            
            return result
        }
    }
    
    public static func firstResult<R: Sendable>(
        from tasks: [Task<R, Error>]
    ) async throws -> R? {
        return try await withThrowingTaskGroup(of: R.self) { group in
            for task in tasks {
                group.addTask {
                    try await withTaskCancellationHandler {
                        try await task.value
                    } onCancel: {
                        task.cancel()
                    }
                }
            }
            
            let result = try await group.next()
            
            group.cancelAll()
            
            return result
        }
    }
}
