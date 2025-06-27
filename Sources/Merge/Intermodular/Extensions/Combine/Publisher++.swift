//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swift

extension Publisher {
    public func throttle(
        for stride: DispatchQueue.SchedulerTimeType.Stride,
        latest: Bool
    ) -> Publishers.Throttle<Self, MainThreadScheduler> {
        self.throttle(for: stride, scheduler: MainThreadScheduler.shared, latest: latest)
    }
    
    public func debounce(
        for stride: DispatchQueue.SchedulerTimeType.Stride
    ) -> Publishers.Debounce<Self, MainThreadScheduler> {
        self.debounce(for: stride, scheduler: MainThreadScheduler.shared)
    }
}

extension Publisher {
    /// Transforms all elements and errors from the upstream publisher to a `Result`.
    public func toResultPublisher() -> Publishers.Catch<Publishers.Map<Self, Result<Output, Failure>>, Just<Result<Output, Failure>>> {
        map(Result.success).catch {
            Just(.failure($0))
        }
    }
    
    public func printOnError() -> Publishers.HandleEvents<Self> {
        handleError({ Swift.print($0) })
    }
    
    public func succeeds() -> AnyPublisher<Bool, Never> {
        map({ _ in true })
            .reduce(true, { $0 && $1 })
            .catch({ _ in Just(false) })
            .eraseToAnyPublisher()
    }
    
    public func fails() -> AnyPublisher<Bool, Never> {
        map({ _ in false })
            .reduce(false, { $0 && $1 })
            .catch({ _ in Just(true) })
            .eraseToAnyPublisher()
    }
    
    public func get<ResultSuccess, ResultFailure>() -> Publishers.FlatMap<Result<ResultSuccess, ResultFailure>.Publisher, Publishers.SetFailureType<Self, ResultFailure>> where Output == Result<ResultSuccess, ResultFailure>, Failure == Never {
        flatMap({ $0.publisher })
    }
    
    public func mapResult<T>(_ transform: @escaping (Result<Output, Failure>) -> T) -> Publishers.Catch<Publishers.Map<Self, T>, Just<T>> {
        map({ transform(Result<Output, Failure>.success($0)) }).catch({ Just(transform(.failure($0))) })
    }
}

extension Publisher {
    @available(*, deprecated, renamed: "sinkAsync")
    public func _asyncSink(
        receiveValue: @escaping (Output) -> Void
    ) async throws {
        try await sinkAsync(receiveValue: receiveValue)
    }
    
    public func sinkAsync(
        receiveValue: @escaping (Output) -> Void
    ) async throws {
        let cancellable = SingleAssignmentAnyCancellable()
        
        let result: Void = try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Void, Error>) in
            cancellable.set(
                sink(
                    receiveCompletion: { (completion: Subscribers.Completion<Self.Failure>) in
                        switch completion {
                            case .finished:
                                continuation.resume(returning: ())
                            case .failure(let failure):
                                continuation.resume(throwing: failure)
                        }
                    },
                    receiveValue: receiveValue
                )
            )
        }

        try Task.checkCancellation()
        
        return result
    }
    
    public func sendValues<E>(
        to subject: some Subject<Output, E>
    ) -> AnyCancellable {
        sink(
            receiveCompletion: { _ in
                
            },
            receiveValue: {
                subject.send($0)
            })
    }
}

extension Publisher {
    public func _opaque_eraseToAnyPublisher() -> any Publisher {
        eraseToAnyPublisher()
    }
    
    public func _eraseToAnyPublisherAnyOutputAnyError() -> AnyPublisher<Any, Swift.Error> {
        map({ $0 as Any }).mapError({ $0 as Swift.Error }).eraseToAnyPublisher()
    }
}
