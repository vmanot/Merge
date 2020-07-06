//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

/// A subject that performs type erasure by wrapping another subject.
public final class AnySubject<Output, Failure: Error>: Subject {
    public let base: Any
    
    @usableFromInline
    let _baseAsAnyPublisher: AnyPublisher<Output, Failure>
    @usableFromInline
    let _sendImpl: (Output) -> ()
    @usableFromInline
    let _sendCompletionImpl: (Subscribers.Completion<Failure>) -> ()
    @usableFromInline
    let _sendSubscriptionImpl: (Subscription) -> ()
    
    public init<S: Subject>(_ subject: S) where S.Output == Output, S.Failure == Failure {
        base = subject
        
        _baseAsAnyPublisher = subject.eraseToAnyPublisher()
        _sendImpl = subject.send
        _sendCompletionImpl = subject.send
        _sendSubscriptionImpl = subject.send
    }
    
    public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        _baseAsAnyPublisher.receive(subscriber: subscriber)
    }
    
    public func send(_ value: Output) {
        _sendImpl(value)
    }
    
    public func send(completion: Subscribers.Completion<Failure>) {
        _sendCompletionImpl(completion)
    }
    
    public func send(subscription: Subscription) {
        _sendSubscriptionImpl(subscription)
    }
}

// MARK: - Auxiliary Implementation -

extension Subject {
    public func eraseToAnySubject() -> AnySubject<Output, Failure> {
        .init(self)
    }
}
