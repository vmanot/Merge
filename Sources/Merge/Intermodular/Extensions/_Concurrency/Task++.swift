//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swallow

extension Task where Success == Never, Failure == Never {
    public static func sleep(
        durationInSeconds duration: Double
    ) async throws {
        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }
}

extension Task {
    public static func _withUnsafeContinuation(
        _ fn: @escaping (UnsafeContinuation<Void, Never>) async -> Success
    ) async -> Task<Success, Failure> where Failure == Never {
        let (task, _) = await Swallow.withAsyncUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) -> Task<Success, Never> in
            return Task<Success, Never> {
                await fn(continuation)
            }
        }
        
        return task
    }

    public static func _withUnsafeThrowingContinuation(
        _ fn: @escaping (UnsafeContinuation<Void, Error>) async throws -> Success
    ) async throws -> Task<Success, Failure> where Failure == Error {
        let (task, _) = try await Swallow.withAsyncUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Void, Error>) -> Task<Success, Error> in
            return Task<Success, Error> {
                try await fn(continuation)
            }
        }
        
        return task
    }
}

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
    
    /// Blocks the current thread and waits for the value.
    ///
    /// **DO NOT USE THIS**.
    ///
    /// Reference:
    /// - https://saagarjha.com/blog/2023/12/22/swift-concurrency-waits-for-no-one/
    @available(*, deprecated, message: "This can result in a deadlock.")
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

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension Task where Failure == Never, Success == Void {
    @discardableResult
    public static func delayed(
        by duration: Duration,
        priority: TaskPriority? = nil,
        perform fn: @escaping () async -> Success
    ) -> Task<Success, Failure> {
        self.init(priority: priority, operation: {
            do {
                try await Task<Never, Never>.sleep(for: duration)
            } catch {
                assertionFailure()
            }
            
            return await fn()
        })
    }
}

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
extension Task where Failure == Never, Success == Void {
    @discardableResult
    public static func delayed(
        by duration: Duration,
        animation: Animation,
        perform fn: @escaping @MainActor () async -> Success
    ) -> Task<Success, Failure> {
        self.init(priority: .userInitiated, operation: { @MainActor in
            do {
                try await Task<Never, Never>.sleep(for: duration)
            } catch {
                assertionFailure()
            }
            
            return await fn()
        })
    }
}
#endif

extension Task where Failure == Error {
    @discardableResult
    public static func retrying(
        priority: TaskPriority? = nil,
        maxRetryCount: Int = 1,
        retryDelay: DispatchTimeInterval? = nil,
        operation: @escaping () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            for _ in 0...maxRetryCount {
                do {
                    try Task<Never, Never>.checkCancellation()

                    let result = try await operation()
                    
                    return result
                } catch {
                    await Task<Never, Never>.yield()

                    if let retryDelay = retryDelay {
                        try await Task<Never, Never>.sleep(retryDelay)
                        
                        await Task<Never, Never>.yield()
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

public func _performRetryingTask<Success>(
    priority: TaskPriority? = nil,
    maxRetryCount: Int = 1,
    retryDelay: DispatchTimeInterval? = nil,
    operation: @escaping () async throws -> Success
) async throws -> Success {
    try await Task.retrying(
        priority: priority,
        maxRetryCount: maxRetryCount,
        retryDelay: retryDelay,
        operation: operation
    ).value
}
