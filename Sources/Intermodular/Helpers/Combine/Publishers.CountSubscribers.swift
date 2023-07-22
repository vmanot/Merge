//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation

extension Publishers {
    public class CountSubscribers<Upstream: Publisher>: Publisher {
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure
        
        private let mutex = NSRecursiveLock()
        
        private var numberOfSubscribers = 0
        
        public let upstream: Upstream
        
        public init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        public func receive<S: Subscriber>(
            subscriber: S
        ) where Failure == S.Failure, Output == S.Input {
            self.increase()
            
            upstream.receive(
                subscriber:
                    ManagedSubscriber<S>(
                        parent: self,
                        subscriber: subscriber
                    )
            )
        }
        
        public func withGuaranteedSubscriberCount(
            _ fn: (Int) -> Void
        ) {
            mutex.withCriticalScope {
                fn(numberOfSubscribers)
            }
        }
        
        fileprivate func increase() {
            mutex.withCriticalScope {
                numberOfSubscribers += 1
            }
        }
        
        fileprivate func decrease() {
            mutex.withCriticalScope {
                numberOfSubscribers -= 1
            }
        }
    }
}

extension Publishers.CountSubscribers {
    private class ManagedSubscriber<S: Subscriber>: Subscriber {
        typealias Input = S.Input
        typealias Failure = S.Failure
        
        let parent: Publishers.CountSubscribers<Upstream>
        let subscriber: S
        
        init(parent: Publishers.CountSubscribers<Upstream>, subscriber: S) {
            self.parent = parent
            self.subscriber = subscriber
        }
        
        func receive(subscription: Subscription) {
            subscriber.receive(
                subscription: ManagedSubscription(
                    parent: parent,
                    subscription: subscription
                )
            )
        }
        
        func receive(_ input: S.Input) -> Subscribers.Demand {
            subscriber.receive(input)
        }
        
        func receive(completion: Subscribers.Completion<S.Failure>) {
            subscriber.receive(completion: completion)
        }
    }
    
    private class ManagedSubscription: Subscription where Upstream: Publisher {
        let lock = OSUnfairLock()
        let parent: Publishers.CountSubscribers<Upstream>
        let base: Subscription
        
        private var cancelled = false
        
        init(parent: Publishers.CountSubscribers<Upstream>, subscription: Subscription) {
            self.parent = parent
            self.base = subscription
        }
        
        func request(_ demand: Subscribers.Demand) {
            base.request(demand)
        }
        
        func cancel() {
            base.cancel()
            
            lock.withCriticalScope {
                if !cancelled {
                    cancelled = true
                    
                    parent.decrease()
                }
            }
        }
        
        deinit {
            lock.withCriticalScope {
                if !cancelled {
                    parent.decrease()
                }
            }
        }
    }
}
