//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publishers {
    /// A publisher created by applying the concatenate function to many upstream publishers.
    ///
    /// Emits all of one publisher's elements before those from the next publisher.
    public struct ConcatenateMany<Upstream>: Publisher where Upstream: Publisher {
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure
        
        public let publishers: [Upstream]
        
        public init(_ publishers: [Upstream]) {
            self.publishers = publishers
        }
        
        public init(_ upstream: Upstream...) {
            self.init(upstream)
        }
        
        public init<S>(_ upstream: S) where Upstream == S.Element, S: Swift.Sequence {
            publishers = Array(upstream)
        }
        
        public func receive<S: Subscriber>(subscriber: S) where ConcatenateMany.Failure == S.Failure, ConcatenateMany.Output == S.Input {
            let initial = AnyPublisher<Upstream.Output, Upstream.Failure>.empty()
            
            publishers.reduce(initial) {
                Concatenate(prefix: $0, suffix: $1).eraseToAnyPublisher()
            }
            .receive(subscriber: subscriber)
        }
    }
}
