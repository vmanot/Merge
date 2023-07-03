//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public func _offTheMainThread<Success>(
    priority: TaskPriority? = nil,
    operation: @escaping () async throws -> Success
) async throws -> Success {
    if Thread._isMainThread {
        return try await Task.detached { @MainActor in
            try await operation()
        }.value
    } else {
        return try await operation()
    }
}

// MARK: - Auxiliary

extension Thread {
    fileprivate static var _isMainThread: Bool {
        isMainThread
    }
}
