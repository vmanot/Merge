//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publishers {
    public struct IndexedPublisher<Upstream>: Publisher where Upstream: Publisher {
        public struct Output {
            let index: Int
            let value: Upstream.Output
        }
        
        public typealias Failure = Upstream.Failure
        
        let index: Int
        let publisher: Upstream
        
        public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            let cancellable = publisher.sink(receiveCompletion: subscriber.receive) { result in
                _ = subscriber.receive(.init(index: self.index, value: result))
            }
            
            subscriber.receive(subscription: AnySubscription(cancellable))
        }
    }
}
