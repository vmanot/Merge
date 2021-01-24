//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Subscribers {
    /// A subscriber that transforms the received subscription with a provided closure.
    public final class MapSubscription<Base: Subscriber>: Subscriber {
        public typealias Input = Base.Input
        public typealias Failure = Base.Failure
        
        private let base: Base
        private let transform: (Subscription) -> Subscription
        
        public init(base: Base, transform: @escaping (Subscription) -> Subscription) {
            self.base = base
            self.transform = transform
        }
        
        public func receive(subscription: Subscription) {
            base.receive(subscription: transform(subscription))
        }
        
        public func receive(_ input: Input) -> Subscribers.Demand {
            base.receive(input)
        }
        
        public func receive(completion: Subscribers.Completion<Failure>) {
            base.receive(completion: completion)
        }
    }
}

// MARK: - API -

extension Subscriber {
    public func mapSubscription(
        _ transform: @escaping (Subscription) -> Subscription
    ) -> Subscribers.MapSubscription<Self> {
        .init(base: self, transform: transform)
    }
}
