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
    public func mapTo<T>(_ value: T) -> Publishers.Map<Self, T> {
        map({ _ in value })
    }
    
    /// Maps all elements from an upstream publisher to a single value.
    public func mapTo<T>(_ value: @escaping () -> T) -> Publishers.Map<Self, T> {
        map({ _ in value() })
    }
    
    public func reduceAndMapTo<T>(_ value: T) -> Publishers.Map<Publishers.Reduce<Self, ()>, T>{
        reduce((), { _, _ in () }).mapTo(value)
    }
}
