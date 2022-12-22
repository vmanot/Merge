//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

/// An actor that can manage a graph of running tasks.
public actor TaskGraph<Key: Hashable> {
    public enum InsertPolicy {
        case discardPrevious
        case useExisting
    }
    
    private var tasks: [Key: OpaqueTask] = [:]
    
    public init() {
        
    }
    
    public init() where Key == AnyHashable {
        
    }
    
    private func pruneTask(withKey key: Key) {
        tasks.removeValue(forKey: key)
    }
    
    private func insertTask<T>(
        withKey key: Key,
        insertionPolicy: InsertPolicy,
        @_implicitSelfCapture operation: @escaping () async throws -> T
    ) -> Task<T, Error> {
        let existingTask = tasks[key]
        
        let result: Task<T, Error>
        
        switch insertionPolicy {
            case .discardPrevious:
                existingTask?.cancel()
                result = Task.detached {
                    let result = try await operation()
                    
                    await self.pruneTask(withKey: key)
                    
                    return result
                }
            case .useExisting:
                if let existingTask = existingTask {
                    result = Task.detached {
                        try await cast(existingTask.value, to: T.self)
                    }
                } else {
                    result = Task.detached {
                        let result = try await operation()
                        
                        await self.pruneTask(withKey: key)
                        
                        return result
                    }
                    
                    tasks[key] = result.eraseToOpaqueTask()
                }
        }
        
        return result
    }
    
    public func insert<T>(
        _ key: Key,
        policy: InsertPolicy,
        @_implicitSelfCapture operation: @escaping () async throws -> T
    ) async throws -> T {
        try await insertTask(withKey: key, insertionPolicy: policy, operation: operation).value
    }
}
