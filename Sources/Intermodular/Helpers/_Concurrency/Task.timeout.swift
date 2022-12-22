//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUI

extension Task where Failure == Error {
    private struct TimeoutError: LocalizedError {
        var errorDescription: String? = "Task timed out before completion."
    }
    
    public init(
        priority: TaskPriority? = nil,
        timeout: TimeInterval,
        operation: @escaping @Sendable () async throws -> Success
    ) {
        self = Task(priority: priority) {
            let result = try await withThrowingTaskGroup(of: Success.self) { group -> Success in
                group.addTask(priority: priority, operation: operation)
                
                group.addTask(priority: priority) {
                    try await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    
                    throw TimeoutError()
                }
                
                guard let success = try await group.next() else {
                    throw _Concurrency.CancellationError()
                }
                
                group.cancelAll()
                
                return success
            }
            
            return result
        }
    }
    
    public init(
        priority: TaskPriority? = nil,
        timeout: DispatchTimeInterval,
        operation: @escaping @Sendable () async throws -> Success
    ) {
        self.init(priority: priority, timeout: try! timeout.toTimeInterval(), operation: operation)
    }
}
