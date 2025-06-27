//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publishers {
    public struct FlatMapLatest<NewPublisher: Publisher, Upstream: Publisher>: Publisher where NewPublisher.Failure == Upstream.Failure {
        public typealias Output = NewPublisher.Output
        public typealias Failure = Upstream.Failure
        
        private let upstream: Upstream
        private let transform: (Upstream.Output) -> NewPublisher
        
        public init(upstream: Upstream, transform: @escaping (Upstream.Output) -> NewPublisher) {
            self.upstream = upstream
            self.transform = transform
        }
        
        public func receive<S: Subscriber>(subscriber: S) where S.Input == NewPublisher.Output, S.Failure == Upstream.Failure {
            upstream
                .map(transform)
                .switchToLatest()
                .receive(subscriber: subscriber)
        }
    }
}

// MARK: - Helpers

extension Publisher {
    public func flatMapLatest<NewPublisher: Publisher>(
        _ transform: @escaping (Output) -> NewPublisher
    ) -> Publishers.FlatMapLatest<NewPublisher, Self>
    where NewPublisher.Failure == Failure {
        return .init(upstream: self, transform: transform)
    }
}
