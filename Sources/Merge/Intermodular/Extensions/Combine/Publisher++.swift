//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swift

extension Publisher {
    public func asyncSink(
        receiveValue: @escaping (Output) -> Void
    ) async throws {
        let cancellable = SingleAssignmentAnyCancellable()
        
        try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Void, Error>) in
            cancellable.set(
                sink(
                    receiveCompletion: { completion in
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
}

extension Publisher {
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
    public func _opaque_eraseToAnyPublisher() -> any Publisher {
        eraseToAnyPublisher()
    }
    
    public func _eraseToAnyPublisherAnyOutputAnyError() -> AnyPublisher<Any, Swift.Error> {
        map({ $0 as Any }).mapError({ $0 as Swift.Error }).eraseToAnyPublisher()
    }
}
