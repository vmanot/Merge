//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift
import SwiftUI

extension Task {
    /// The result of this task expressed as a publisher.
    public func publisher(
        priority: TaskPriority? = nil
    ) -> AnySingleOutputPublisher<Success, Failure> {
        Future.async(priority: priority) { () -> Result<Success, Failure> in
            await self.result
        }
        .flatMap { (result: Result<Success, Failure>) -> AnyPublisher<Success, Failure> in
            switch result {
                case .success(let success):
                    return Just(success).setFailureType(to: Failure.self).eraseToAnyPublisher()
                case .failure(let failure):
                    return Fail(error: failure).eraseToAnyPublisher()
            }
        }
        .handleEvents(receiveCancel: self.cancel)
        ._unsafe_eraseToAnySingleOutputPublisher()
    }
    
    /// Block the current thread and wait for the value.
    public func blockAndWaitForValue() throws -> Success {
        try Future.async {
            try await value
        }
        .subscribeAndWaitUntilDone()
        .unwrap()
        .get()
    }
}

extension Task where Success == Never, Failure == Never {
    /// Suspends the current task for at least the given duration.
    public static func sleep(_ duration: DispatchTimeInterval) async throws {
        switch duration {
            case .seconds(let int):
                try await sleep(nanoseconds: UInt64(int) * 1_000_000_000)
            case .milliseconds(let int):
                try await sleep(nanoseconds: UInt64(int) * 1_000_000)
            case .microseconds(let int):
                try await sleep(nanoseconds: UInt64(int) * 1_000)
            case .nanoseconds(let int):
                try await sleep(nanoseconds: UInt64(int))
            case .never:
                break
            @unknown default:
                fatalError()
        }
    }
}

extension Task where Success == Void, Failure == Error {
    /// Runs the given asynchronous operation repeatedly while a given predicate evaluates to `true`.
    public static func `repeat`(
        while predicate: @escaping () throws -> Bool,
        maxRepetitions: Int = Int.maximum,
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
    public static func `repeat`(
        every interval: DispatchTimeInterval,
        on runLoop: RunLoop = .main,
        operation: @escaping () async throws -> Void
    ) throws -> Task {
        let interval = try interval.toTimeInterval()
        
        let _runLoop = UncheckedSendable(wrappedValue: runLoop)
        
        return _Concurrency.Task {
            try _Concurrency.Task.checkCancellation()

            for await _ in Timer.publish(every: interval, on: _runLoop.wrappedValue, in: .default).autoconnect().values {
                try _Concurrency.Task.checkCancellation()
                
                try await operation()
            }
        }
    }
}

extension Task where Failure == Error {
    @discardableResult
    public static func retrying(
        priority: TaskPriority? = nil,
        maxRetryCount: Int = 3,
        retryDelay: DispatchTimeInterval,
        operation: @escaping () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            for _ in 0..<maxRetryCount {
                do {
                    return try await operation()
                } catch {
                    try await Task<Never, Never>.sleep(retryDelay)
                    
                    continue
                }
            }
            
            try Task<Never, Never>.checkCancellation()
            
            return try await operation()
        }
    }
}

// MARK: - SwiftUI -

extension Task {
    /// Bind this task to a `Binding`.
    ///
    /// - Parameters:
    ///   - taskBinding: The `Binding` to set when this task starts, and clear when this task ends/errors out.
    public func bind(to taskBinding: Binding<OpaqueTask?>) {
        let erasedTask = OpaqueTask(erasing: self)
        
        _Concurrency.Task { @MainActor in
            taskBinding.wrappedValue = erasedTask
            
            _ = try await self.value
            
            taskBinding.wrappedValue = nil
        }
    }
}
