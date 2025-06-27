//
// Copyright (c) Vatsal Manot
//

import Combine
import FoundationX
import Swallow

public final class _MultiReaderSubject<Output, Failure: Error> {
    private let base = PassthroughSubject<(sender: Child.ID, payload: Result<Output, Failure>), Never>()
    private let rootID = Child.ID()
    
    public init() {
        
    }
    
    public func child() -> Child {
        .init(parent: self, id: .init())
    }
}

extension _MultiReaderSubject: Publisher {
    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        let rootID = self.rootID
        
        base
            .filter({ $0.sender != rootID })
            .tryMap({ try $0.payload.get() })
            .mapError({ $0 as! Failure })
            .receive(subscriber: subscriber)
    }
}

extension _MultiReaderSubject: Subject {
    public func send(_ value: Output) {
        base.send((rootID, .success(value)))
    }
    
    public func send(completion: Subscribers.Completion<Failure>) {
        switch completion {
            case .finished:
                base.send(completion: .finished)
            case .failure(let error):
                base.send((rootID, .failure(error)))
        }
    }
    
    public func send(subscription: Subscription) {
        base.send(subscription: subscription)
    }
}

extension _MultiReaderSubject {
    public final class Child: Publisher, Subject {
        public typealias ID = _AutoIncrementingIdentifier<Child>
        
        private let parent: _MultiReaderSubject
        private let id: ID
        
        fileprivate init(parent: _MultiReaderSubject, id: ID) {
            self.parent = parent
            self.id = id
        }
        
        public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            let id = self.id
            
            parent.base
                .filter({ $0.sender != id })
                .tryMap({ try $0.payload.get() })
                .mapError({ $0 as! Failure })
                .receive(subscriber: subscriber)
        }
        
        public func send(_ value: Output) {
            parent.base.send((id, .success(value)))
        }
        
        public func send(completion: Subscribers.Completion<Failure>) {
            switch completion {
                case .finished:
                    parent.base.send(completion: .finished)
                case .failure(let error):
                    parent.base.send((id, .failure(error)))
            }
        }
        
        public func send(subscription: Subscription) {
            parent.base.send(subscription: subscription)
        }
    }
}
