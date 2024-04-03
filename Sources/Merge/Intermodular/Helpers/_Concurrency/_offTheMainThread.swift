//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension Task {
    @discardableResult
    public static func _offTheMainThread(
        priority: TaskPriority? = nil,
        operation: @escaping () async -> Success
    ) -> Self where Failure == Never {
        if Thread._isMainThread {
            return Task.detached(priority: priority) {
                assert(!Thread._isMainThread)
                
                return await operation()
            }
        } else {
            return Task(priority: priority) {
                if Thread._isMainThread {
                    let task = await MainActor.run {
                        Task.detached(priority: priority) {
                            assert(!Thread._isMainThread)
                            
                            return await operation()
                        }
                    }
                    
                    return await task.value
                } else {
                    return await operation()
                }
            }
        }
    }

    @discardableResult
    public static func _offTheMainThread(
        priority: TaskPriority? = nil,
        operation: @escaping () async throws -> Success
    ) -> Self where Failure == Swift.Error {
        if Thread._isMainThread {
            return Task.detached(priority: priority) {
                assert(!Thread._isMainThread)
                
                return try await operation()
            }
        } else {
            return Task(priority: priority) {
                if Thread._isMainThread {
                    let task = await MainActor.run {
                        Task.detached(priority: priority) {
                            assert(!Thread._isMainThread)
                            
                            return try await operation()
                        }
                    }
                    
                    return try await task.value
                } else {
                    return try await operation()
                }
            }
        }
    }
}

public func _offTheMainThread<Success>(
    priority: TaskPriority? = nil,
    operation: @escaping () async -> Success
) async -> Success {
    await Task._offTheMainThread(priority: priority, operation: operation).value
}

public func _offTheMainThread<Success>(
    priority: TaskPriority? = nil,
    operation: @escaping () async throws -> Success
) async throws -> Success {
    try await Task._offTheMainThread(priority: priority, operation: operation).value
}
