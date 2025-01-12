//
// Copyright (c) Vatsal Manot
//

import Swift

/// A publisher that delivers the result of a task.
public struct TaskSuccessPublisher<Upstream: ObservableTask> {
    private let upstream: Upstream
    
    public init(upstream: Upstream) {
        self.upstream = upstream
    }
    
    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Output, S.Failure == Failure {
        upstream
            .outputPublisher
            .compactMap({ $0.value })
            .receive(subscriber: subscriber)
    }
}

extension TaskSuccessPublisher: SingleOutputPublisher {
    public typealias Output = Upstream.Success
    public typealias Failure = ObservableTaskFailure<Upstream.Error>
}

// MARK: - API

extension ObservableTask {
    /// A publisher that delivers the result of a task.
    public var successPublisher: TaskSuccessPublisher<Self> {
        .init(upstream: self)
    }
    
    /// The successful result of a task, after it completes.
    ///
    /// - returns: The task's successful result.
    /// - throws: An error indicating task failure or task cancellation.
    public var value: Success {
        get async throws {
            do {
                let result: Success = try await successPublisher.output()
                
                return result
            } catch {
                if let error = error as? ObservableTaskFailureProtocol {
                    if let unwrappedError: any Swift.Error = error._opaque_error {
                        throw unwrappedError
                    }
                }
                
                throw error
            }
        }
    }
}
