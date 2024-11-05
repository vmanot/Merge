//
// Copyright (c) Vatsal Manot
//

import Darwin
import Swallow

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public protocol TaskRetryDelayStrategy: Hashable, Sendable {
    func delay(
        forAttempt attempt: Int,
        withInitialDelay initial: Duration
    ) -> Duration
}

// MARK: - Standard Implementations

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public struct LinearBackoffStrategy: TaskRetryDelayStrategy {
    public func delay(
        forAttempt attempt: Int,
        withInitialDelay initial: Duration
    ) -> Duration {
        initial * Double(attempt)
    }
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension TaskRetryDelayStrategy where Self == LinearBackoffStrategy {
    public static var linear: Self {
        .init()
    }
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
public struct ExponentialBackoffStrategy: TaskRetryDelayStrategy {
    public let maximumInterval: Duration?
    public let jitter: Bool
    
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    public func delay(
        forAttempt attempt: Int,
        withInitialDelay initial: Duration
    ) -> Duration {
        var delay = initial * pow(2, Double(attempt - 1))
        
        if let maximumInterval {
            delay = min(delay, maximumInterval)
        }
        
        if jitter {
            return Duration(_timeInterval: Double.random(in: 0...delay._timeInterval))
        } else {
            return delay
        }
    }
}

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension TaskRetryDelayStrategy where Self == ExponentialBackoffStrategy {
    public static func exponentialBackoff(
        maximumInterval: Duration? = nil,
        jitter: Bool = true
    ) -> Self {
        .init(maximumInterval: nil, jitter: jitter)
    }
    
    public static var exponentialBackoff: Self {
        self.exponentialBackoff()
    }
}
