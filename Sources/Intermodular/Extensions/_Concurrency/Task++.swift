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
