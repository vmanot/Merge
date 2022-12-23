//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUI

extension Task where Failure == Error {
    fileprivate struct TimeoutError: LocalizedError {
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
    
    public static func detached(
        priority: TaskPriority? = nil,
        timeout: TimeInterval,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        Task.detached(priority: priority) {
            try await _runOperationWithTimeout(operation, timeout: timeout)
        }
    }
    
    public static func detached(
        priority: TaskPriority? = nil,
        timeout: DispatchTimeInterval,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        detached(priority: priority, timeout: try! timeout.toTimeInterval(), operation: operation)
    }

    public func value(timeout: TimeInterval) async throws -> Success {
        try await _runOperationWithTimeout({ try await self.value }, timeout: timeout)
    }
    
    public func value(timeout: DispatchTimeInterval) async throws -> Success {
        try await self.value(timeout: timeout.toTimeInterval())
    }
}

private func _runOperationWithTimeout<Success>(
    _ operation: @escaping () async throws -> Success,
    timeout: TimeInterval
) async throws -> Success {
    try await withThrowingTaskGroup(of: Success.self) { group -> Success in
        group.addTask(operation: { try await operation() })
        
        group.addTask {
            try await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            
            throw Task<Success, Error>.TimeoutError()
        }
        
        guard let success = try await group.next() else {
            throw _Concurrency.CancellationError()
        }
        
        group.cancelAll()
        
        return success
    }
}
