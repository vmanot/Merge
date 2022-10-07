//
// Copyright (c) Vatsal Manot
//

import Swallow

public actor AsyncSemaphore {
    private let limit: Int
    private var count = 0
    private var queue = [UnsafeContinuation<Void, Never>]() // [lines: 5]
    
    init(_ limit: Int = 1) {
        precondition(limit > 0)
        
        self.limit = limit
    }
    
    public func wait() async {
        if count < limit {
            count += 1
        } else {
            return await withUnsafeContinuation { continuation in
                queue.append(continuation)
            }
        }
    }
    
    public func signal() {
        precondition(count > 0)
        
        if queue.isEmpty {
            count -= 1
        } else {
            queue.removeFirst().resume()
        }
    }
    
    public func withCriticalScope<T>(
        _ block: @Sendable () async throws -> T
    ) async rethrows -> T {
        await wait()
        
        defer {
            signal()
        }
        
        return try await block()
    }
}
