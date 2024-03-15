//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public actor AsyncPassthroughSubject<Element>: Initiable, Publisher {
    public typealias Output = Element
    public typealias Failure = Never
    
    package var tasks: [AsyncStream<Element>.Continuation] = []
    private var combineSubscribers = [CombineBridge]()
    
    deinit {
        tasks.forEach {
            $0.finish()
        }
    }
    
    public init() {
        
    }
    
    public func notifications() -> AsyncStream<Element> {
        AsyncStream { [weak self] continuation in
            let task = Task { [weak self] in
                await self?.storeContinuation(continuation)
            }
            
            continuation.onTermination = { termination in
                task.cancel()
            }
        }
    }
    
    nonisolated public func receive<S>(
        subscriber: S
    ) where S : Subscriber, Never == S.Failure, Element == S.Input {
        let subscription = CombineBridge(self, AnySubscriber(subscriber))
        
        subscriber.receive(subscription: subscription)
    }
    
    nonisolated public func send(_ element: Element) {
        Task {
            await self._send(element)
        }
    }
    
    private func _send(_ element: Element) {
        tasks.forEach { $0.yield(element) }
        combineSubscribers.forEach { _ = $0.receive(element) }
    }
    
    private func storeContinuation(_ continuation: AsyncStream<Element>.Continuation) {
        tasks.append(continuation)
    }
    
    nonisolated public func finish() {
        Task {
            await self._finish()
        }
    }
    
    private func _finish() {
        tasks.forEach {
            $0.finish()
        }
        tasks.removeAll()
        
        combineSubscribers.forEach {
            $0.receive(completion: .finished)
        }
        
        combineSubscribers.removeAll()
    }
    
    private class CombineBridge: Subscriber, Subscription {
        typealias Input = Element
        typealias Failure = Never
        
        private var subscription: Subscription?
        private let subject: AsyncPassthroughSubject
        private var subscriber: AnySubscriber<Element, Failure>?
        
        init(
            _ subject: AsyncPassthroughSubject,
            _ subscriber: AnySubscriber<Element, Failure>
        ) {
            self.subject = subject
            self.subscriber = subscriber
            
            Task {
                await subject.registerCombineSubscriber(self)
            }
        }
        
        func receive(subscription: Subscription) {
            self.subscription = subscription
            subscriber?.receive(subscription: self)
        }
        
        func receive(_ input: Element) -> Subscribers.Demand {
            return subscriber?.receive(input) ?? .none
        }
        
        func receive(completion: Subscribers.Completion<Never>) {
            subscriber?.receive(completion: completion)
            subscriber = nil
        }
        
        func request(_ demand: Subscribers.Demand) {
            // Implement demand management if necessary
        }
        
        func cancel() {
            Task {
                await subject.unregisterCombineSubscriber(self)
            }
            subscriber = nil
        }
    }
    
    private func registerCombineSubscriber(
        _ subscriber: CombineBridge
    ) {
        combineSubscribers.append(subscriber)
    }
    
    private func unregisterCombineSubscriber(
        _ subscriber: CombineBridge
    ) {
        combineSubscribers.removeAll { $0 === subscriber }
    }
}
