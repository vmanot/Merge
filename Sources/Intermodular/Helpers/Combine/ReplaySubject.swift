//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

public final class ReplaySubject<Output, Failure: Error>: Subject {
    private var buffer = [Output]()
    private let bufferSize: Int
    private var subscriptions = [_Subscription]()
    private var completion: Subscribers.Completion<Failure>?
    private let lock = NSRecursiveLock()
    
    public init(_ bufferSize: Int = 0) {
        self.bufferSize = bufferSize
    }
    
    /// Provides this Subject an opportunity to establish demand for any new upstream subscriptions
    public func send(subscription: Subscription) {
        lock.lock()
        
        defer {
            lock.unlock()
        }
        
        subscription.request(.unlimited)
    }
    
    /// Sends a value to the subscriber.
    public func send(_ value: Output) {
        lock.lock()
        
        defer {
            lock.unlock()
        }
        
        buffer.append(value)
        buffer = buffer.suffix(bufferSize)
        
        subscriptions.forEach({ $0.receive(value) })
    }
    
    /// Sends a completion signal to the subscriber.
    public func send(completion: Subscribers.Completion<Failure>) {
        lock.lock()
        
        defer {
            lock.unlock()
        }
        
        self.completion = completion
        
        subscriptions.forEach { subscription in
            subscription.receive(completion: completion)
        }
    }
    
    /// This function is called to attach the specified `Subscriber` to the`Publisher
    public func receive<Downstream: Subscriber>(subscriber: Downstream) where Downstream.Failure == Failure, Downstream.Input == Output {
        lock.lock()
        
        defer {
            lock.unlock()
        }
        
        let subscription = _Subscription(downstream: AnySubscriber(subscriber))
        
        subscriber.receive(subscription: subscription)
        
        subscriptions.append(subscription)
        
        subscription.replay(buffer, completion: completion)
    }
}

// MARK: - API -

extension Publisher {
    /// Provides a subject that shares a single subscription to the upstream publisher and replays at most `bufferSize` items emitted by that publisher
    /// - Parameter bufferSize: limits the number of items that can be replayed
    public func shareReplay(_ bufferSize: Int) -> AnyPublisher<Output, Failure> {
        return multicast(subject: ReplaySubject(bufferSize)).autoconnect().eraseToAnyPublisher()
    }
}

// MARK: - Auxiliary Implementation -

extension ReplaySubject {
    public final class _Subscription: Combine.Subscription {
        private let downstream: AnySubscriber<Output, Failure>
        private var isCompleted = false
        private var demand: Subscribers.Demand = .none
        
        public init(downstream: AnySubscriber<Output, Failure>) {
            self.downstream = downstream
        }
        
        public func request(_ newDemand: Subscribers.Demand) {
            demand += newDemand
        }
        
        public func receive(_ value: Output) {
            guard !isCompleted, demand > 0 else {
                return
            }
            
            demand += downstream.receive(value)
            demand -= 1
        }
        
        public func receive(completion: Subscribers.Completion<Failure>) {
            guard !isCompleted else {
                return
            }
            
            isCompleted = true
            
            downstream.receive(completion: completion)
        }
        
        public func replay(_ values: [Output], completion: Subscribers.Completion<Failure>?) {
            guard !isCompleted else {
                return
            }
            
            values.forEach(receive)
            
            if let completion = completion {
                receive(completion: completion)
            }
        }
        
        public func cancel() {
            isCompleted = true
        }
    }
}
