//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift

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

extension Task where Failure == Error {
    @discardableResult
    public static func retrying(
        priority: TaskPriority? = nil,
        maxRetryCount: Int,
        retryDelay: DispatchTimeInterval? = nil,
        operation: @escaping () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            for _ in 0..<maxRetryCount {
                do {
                    try Task<Never, Never>.checkCancellation()

                    let result = try await operation()
                    
                    return result
                } catch {
                    if let retryDelay = retryDelay {
                        try await Task<Never, Never>.sleep(retryDelay)
                    }
                    
                    continue
                }
            }
            
            try Task<Never, Never>.checkCancellation()
            
            let result = try await operation()
            
            return result
        }
    }
}
