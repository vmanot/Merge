//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public enum _RetryStrategy {
    case delay(any RetryDelayStrategy, initial: Duration)
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public struct _RetryPolicy {
    public var strategy: _RetryStrategy
    public let maxRetryCount: Int?
    public let onFailure: (Error, Int) throws -> ()
    
    public init(
        strategy: _RetryStrategy,
        maxRetryCount: Int? = 1,
        onFailure: @escaping (Error, Int) throws -> () = { _, _ in }
    ) {
        self.strategy = strategy
        self.maxRetryCount = maxRetryCount
        self.onFailure = onFailure
    }
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public enum _RetryError: Error {
    case maximumRetriesExceeded(Int)
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public func _performTask<Result>(
    retryPolicy: _RetryPolicy?,
    operation: () async throws -> Result
) async throws -> Result {
    guard let retryPolicy else {
        return try await operation()
    }
    
    switch retryPolicy.strategy {
        case .delay(let delay, let initial): do {
            var attempt = 1
            
            while true {
                try Task.checkCancellation()
                
                do {
                    return try await operation()
                } catch {
                    try retryPolicy.onFailure(error, attempt)
                }
                
                if let maxRetryCount = retryPolicy.maxRetryCount, (attempt - 1) > maxRetryCount {
                    throw _RetryError.maximumRetriesExceeded(maxRetryCount)
                }
                
                let delay = delay.delay(forAttempt: attempt, withInitialDelay: initial)
                
                try await Task.sleep(for: delay)
                
                attempt += 1
            }
        }
    }
}
