//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publishers {
    public struct While<DeferredPublisher: Publisher>: Publisher {
        public typealias Output = DeferredPublisher.Output
        public typealias Failure = DeferredPublisher.Failure
        
        public let condition: () -> Bool
        public let createPublisher: () -> DeferredPublisher
        
        public init(
            condition: @escaping () -> Bool,
            createPublisher: @escaping () -> DeferredPublisher
        ) {
            self.condition = condition
            self.createPublisher = createPublisher
        }
        
        public init(
            _ condition: @autoclosure @escaping () -> Bool,
            createPublisher: @escaping () -> DeferredPublisher
        ) {
            self.init(condition: condition, createPublisher: createPublisher)
        }
        
        public func receive<S: Subscriber>(
            subscriber: S
        ) where S.Input == Output, S.Failure == Failure {
            if condition() {
                createPublisher()
                    .append(Publishers.While(condition: condition, createPublisher: createPublisher))
                    .receive(subscriber: subscriber)
            } else {
                Empty(completeImmediately: true)
                    .receive(subscriber: subscriber)
            }
        }
    }
}
