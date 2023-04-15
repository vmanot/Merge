//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Foundation
import Swift

extension Task where Success == Void, Failure == Error {
    /// Runs the given asynchronous operation repeatedly while a given predicate evaluates to `true`.
    @discardableResult
    public static func `repeat`(
        while predicate: @escaping @Sendable () throws -> Bool,
        maxRepetitions: Int = Int.max,
        _ operation: @escaping () async throws -> Void
    ) -> Task<Success, Failure> {
        Task {
            var numberOfRepetitions: Int = 0
            
            while try numberOfRepetitions <= maxRepetitions && (try predicate())  {
                try await operation()
                
                numberOfRepetitions += 1
            }
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension Task where Success == Void, Failure == Error {
    /// Runs the given asynchronous operation repeatedly on the given interval on behalf of the current actor.
    @discardableResult
    public static func `repeat`(
        every interval: DispatchTimeInterval,
        on runLoop: RunLoop = .main,
        operation: @escaping () async throws -> Void
    ) throws -> Task {
        let interval = try interval.toTimeInterval()
        
        let _runLoop = _UncheckedSendable(wrappedValue: runLoop)
        
        return _Concurrency.Task {
            try _Concurrency.Task.checkCancellation()
            
            for await _ in Timer.publish(every: interval, on: _runLoop.wrappedValue, in: .default).autoconnect().values {
                try _Concurrency.Task.checkCancellation()
                
                try await operation()
            }
        }
    }
}
