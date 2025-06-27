//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

extension Publishers {
    public struct With<Value, Mutation: Publisher>: SingleOutputPublisher {
        public typealias Output = Value
        public typealias Failure = Mutation.Failure
        
        public let initial: Value
        public let mutation: (_: Inout<Value>) -> Mutation
        
        public init(
            _ initial: Value,
            mutation: @escaping (Inout<Value>) -> Mutation
        ) {
            self.initial = initial
            self.mutation = mutation
        }
        
        public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            subscriber.receive(subscription: Subscription(initial: initial, mutation: mutation, subscriber: .init(subscriber)))
        }
        
        private final class Subscription: Combine.Subscription {
            private let state: MutexProtected<Value, OSUnfairLock>
            private let mutation: (Inout<Value>) -> Mutation
            private var subscriber: AnySubscriber<Output, Failure>?
            
            private var stateAccessor: Inout<Value>?
            private var mutationSubscription: AnyCancellable?
            
            public init(
                initial: Value,
                mutation: @escaping (Inout<Value>) -> Mutation,
                subscriber: AnySubscriber<Output, Failure>
            ) {
                self.state = .init(wrappedValue: initial)
                self.mutation = mutation
                self.subscriber = subscriber
                
                self.stateAccessor = Inout(get: { self.state.assignedValue }, set: { self.state.assignedValue = $0 })
            }
            
            public func request(_ demand: Subscribers.Demand) {
                guard mutationSubscription == nil else {
                    return
                }
                
                guard let subscriber = subscriber, let stateAccessor = stateAccessor else {
                    return
                }
                
                if demand == .unlimited {
                    mutationSubscription = mutation(stateAccessor)
                        .sink(
                            receiveCompletion: { completion in
                                switch completion {
                                    case .finished:
                                        do {
                                            _ = subscriber.receive(self.state.assignedValue)
                                            
                                            subscriber.receive(completion: .finished)
                                        }
                                    case .failure(let error):
                                        do {
                                            subscriber.receive(completion: .failure(error))
                                        }
                                }
                            },
                            receiveValue: { _ in
                                
                            })
                }
            }
            
            public func cancel() {
                subscriber = nil
                stateAccessor = nil
                mutationSubscription = nil
            }
        }
    }
}
