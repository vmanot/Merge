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
            try await _runOperationWithTimeout(operation, timeout: timeout)
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

private func _runOperationWithTimeout<Success: Sendable>(
    _ operation: @escaping @Sendable () async throws -> Success,
    timeout: TimeInterval
) async throws -> Success {
    try await withThrowingTaskGroup(of: Success.self) { group -> Success in
        await withUnsafeContinuation { continuation in
            group.addTask {
                continuation.resume()

                return try await operation()
            }
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            
            throw Task<Success, Error>.TimeoutError()
        }
        
        guard let success = try await group.next() else {
            throw _Concurrency.CancellationError()
        }
        
        group.cancelAll()
        
        return success
    }
}

extension Task where Failure == Error {
    public static func _detached(
        priority: TaskPriority? = nil,
        timeout: TimeInterval,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task<Success, Failure> {
        Task.detached(priority: priority) {
            try await Task.run(operation: operation, withTimeout: timeout)
        }
    }

    public static func _detached(
        priority: TaskPriority? = nil,
        timeout: DispatchTimeInterval,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task<Success, Failure> {
        _detached(priority: priority, timeout: try! timeout.toTimeInterval(), operation: operation)
    }
    
    private actor TimeoutActor {
        private var isCompleted = false
        
        func markCompleted() -> Bool {
            if self.isCompleted {
                return false
            }
            
            self.isCompleted = true
            
            return true
        }
    }
    
    private static func run(
        operation: @escaping @Sendable () async throws -> Success,
        withTimeout timeout: TimeInterval
    ) async throws -> Success {
        return try await withUnsafeThrowingContinuation({ (continuation: UnsafeContinuation<Success, Error>) in
            let timeoutActor = TimeoutActor()
            
            Task<Void, Never> {
                do {
                    let operationResult = try await operation()
                    if await timeoutActor.markCompleted() {
                        continuation.resume(returning: operationResult)
                    }
                }
                catch {
                    if await timeoutActor.markCompleted() {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            Task<Void, Never> {
                do {
                    try await _Concurrency.Task.sleep(nanoseconds: UInt64(timeout) * 1_000_000_000)
                    if await timeoutActor.markCompleted() {
                        continuation.resume(throwing: Task<Success, Error>.TimeoutError())
                    }
                }
                catch {
                    if await timeoutActor.markCompleted() {
                        continuation.resume(throwing: error)
                    }
                }
            }
        })
    }
}
