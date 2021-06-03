//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publisher {
    @_disfavoredOverload
    public func flatMap<P>(
        maxPublishers: Subscribers.Demand = .unlimited,
        _ transform: @escaping (Self.Output) -> P
    ) -> Publishers.FlatMap<P, Publishers.SetFailureType<Self, P.Failure>> {
        .init(upstream: self.setFailureType(to: P.Failure.self), maxPublishers: maxPublishers, transform: transform)
    }
    
    @_disfavoredOverload
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
    ) -> Publishers.FlatMap<Publishers.MapError<P, Error>, Self> {
        flatMap(maxPublishers: maxPublishers) { output in
            transform(output)
                .eraseError()
        }
    }
    
    public func flatMap<P: Publisher, T>(
        _ keyPath: KeyPath<Output, T>,
        maxPublishers: Subscribers.Demand = .unlimited,
        _ transform: @escaping (T) -> P
    ) -> Publishers.FlatMap<Publishers.MapError<P, Error>, Self> {
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
