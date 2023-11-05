//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publishers {
    public struct MapSubscriber<Upstream: Publisher, Subscriber: Combine.Subscriber>: Publisher where Subscriber.Input == Upstream.Output, Subscriber.Failure == Upstream.Failure {
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure
        
        private let upstream: Upstream
        private let transform: (AnySubscriber<Output, Failure>) -> Subscriber
        
        public init(
            upstream: Upstream,
            transform: @escaping (AnySubscriber<Output, Failure>) -> Subscriber
        ) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: Combine.Subscriber>(
            subscriber: S
        ) where S.Input == Output, S.Failure == Failure {
            upstream.receive(subscriber: transform(.init(subscriber)))
        }
    }
}

extension Publisher {
    public func mapSubscriber<S: Subscriber>(
        _ transform: @escaping (AnySubscriber<Output, Failure>) -> S
    ) -> Publishers.MapSubscriber<Self, S> {
        .init(upstream: self, transform: transform)
    }
}
