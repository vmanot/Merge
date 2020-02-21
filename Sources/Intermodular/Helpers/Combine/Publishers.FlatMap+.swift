//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publisher {
    /// Transforms all elements from an upstream publisher into an empty publisher.
    public func mapToEmpty(completeImmediately: Bool = true) -> Publishers.FlatMap<Empty<Output, Failure>, Self> {
        flatMap({ _ in Empty<Output, Failure>(completeImmediately: completeImmediately) })
    }
    
    /// Transforms all elements from an upstream publisher into an empty publisher.
    public func mapToEmpty<T, U: Error>(
        completeImmediately: Bool = true,
        outputType: Output.Type = Output.self,
        failureType: Failure.Type = Failure.self
    ) -> Publishers.FlatMap<Empty<T, U>, Self> {
        flatMap({ _ in Empty<T, U>(completeImmediately: completeImmediately) })
    }
    
    /// Maps all elements from an upstream publisher to a single value.
    public func mapTo<T>(_ value: T) -> Publishers.FlatMap<Result<T, Failure>.Publisher, Self> {
        flatMap({ _ in Just(value).setFailureType(to: Failure.self) })
    }
    
    public func flatMap<P: Publisher>(
        maxPublishers: Subscribers.Demand = .unlimited,
        _ transform: @escaping (Output) -> P
    ) -> Publishers.FlatMap<Publishers.MapError<P, Error>, Publishers.MapError<Self, Error>>  {
        eraseError().flatMap(maxPublishers: maxPublishers) { output in
            transform(output)
                .eraseError()
        }
    }
}

extension Publisher where Failure == Error {
    public func flatMap<P: Publisher>(
        maxPublishers: Subscribers.Demand = .unlimited,
        _ transform: @escaping (Output) -> P
    ) -> Publishers.FlatMap<Publishers.MapError<P, Error>, Self>  {
        flatMap(maxPublishers: maxPublishers) { output in
            transform(output)
                .eraseError()
        }
    }
    
    public func flatMap<P: Publisher, T>(
        _ keyPath: KeyPath<Output, T>,
        maxPublishers: Subscribers.Demand = .unlimited,
        _ transform: @escaping (T) -> P
    ) -> Publishers.FlatMap<Publishers.MapError<P, Error>, Self>  {
        flatMap(maxPublishers: maxPublishers) { output in
            transform(output[keyPath: keyPath])
                .eraseError()
        }
    }

    public func flatMap<P: Publisher>(
        from publisher: P
    ) -> Publishers.FlatMap<Publishers.MapError<Self, Error>, Publishers.MapError<P, Error>> {
        publisher
            .eraseError()
            .flatMap { _ in self }
    }
}
