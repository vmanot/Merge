//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public enum _TaskRetryStrategy: Sendable {
    case delay(any TaskRetryDelayStrategy, initial: Duration)
    
    public static func delay(
        _ strategy: some TaskRetryDelayStrategy
    ) -> Self {
        .delay(strategy, initial: .seconds(1))
    }
    
    public static func delay(
        duration: Duration
    ) -> Self {
        .delay(.linear, initial: .seconds(1))
    }
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public struct _TaskRetryPolicy: Sendable {
    public var strategy: _TaskRetryStrategy
    public let maxRetryCount: Int?
    public let onFailure: @Sendable (Error, Int) throws -> ()
    
    public init(
        strategy: _TaskRetryStrategy,
        maxRetryCount: Int? = 1,
        onFailure: @escaping @Sendable (Error, Int) throws -> () = { _, _ in }
    ) {
        self.strategy = strategy
        self.maxRetryCount = maxRetryCount
        self.onFailure = onFailure
    }
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public enum _TaskRetryError: Error {
    case maximumRetriesExceeded(Int)
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public func withTaskRetryPolicy<Result>(
    _ retryPolicy: _TaskRetryPolicy?,
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
                    throw _TaskRetryError.maximumRetriesExceeded(maxRetryCount)
                }
                
                let delay = delay.delay(forAttempt: attempt, withInitialDelay: initial)
                
                try await Task.sleep(for: delay)
                
                attempt += 1
            }
        }
    }
}
