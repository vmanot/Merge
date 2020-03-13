//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift

/// A thread-safe collection suitable for storing instanes of `AnyCancellable`.
public final class Cancellables: Cancellable {
    private var queue = DispatchQueue(label: "Merge.Cancellables.maintenance")
    private var cancellables: Set<AnyCancellable> = []
    
    public init() {
        
    }
    
    public func insert(_ cancellable: AnyCancellable) {
        queue.async {
            self.cancellables.insert(cancellable)
        }
    }
    
    public func remove(_ cancellable: AnyCancellable) {
        queue.async {
            self.cancellables.remove(cancellable)
        }
    }
    
    public func cancel() {
        queue.async {
            self.cancellables.forEach({ $0.cancel() })
            self.cancellables.removeAll()
        }
    }
    
    public func subscribe<P: Publisher>(to publisher: P) {
        let _cancellable = SingleAssignmentAnyCancellable()
        let cancellable = AnyCancellable(_cancellable)
        
        insert(cancellable)
        
        let __cancellable = publisher.handleCancelOrCompletion { [weak self] _ in
            self?.remove(cancellable)
        }.sink()
        
        queue.sync {
            _cancellable.set(__cancellable)
        }
    }
    
    public func subscribe<S: Subject, P: Publisher>(_ subject: S, to publisher: P) where S.Output == P.Output, S.Failure == P.Failure {
        let _cancellable = SingleAssignmentAnyCancellable()
        let cancellable = AnyCancellable(_cancellable)
        
        insert(cancellable)
        
        let __cancellable = publisher.handleCancelOrCompletion { [weak self] _ in
            self?.remove(cancellable)
        }.subscribe(subject)
        
        queue.sync {
            _cancellable.set(__cancellable)
        }
    }
    
    public func subscribe<S: Subscriber, P: Publisher>(_ subscriber: S, to publisher: P) where S.Input == P.Output, S.Failure == P.Failure {
        let cancellable = AnyCancellable(CancellableRetain(subscriber))
        
        insert(cancellable)
        
        publisher.handleEvents(
            receiveCompletion: { [weak self] _ in self?.remove(cancellable) },
            receiveCancel: { [weak self] in self?.remove(cancellable) }
        ).receive(subscriber: subscriber)
    }
}

// MARK: - Helpers -

extension AnyCancellable {
    public func store(in cancellables: Cancellables) {
        cancellables.insert(self)
    }
}

extension Publisher {
    public func subscribe(storeIn cancellables: Cancellables) {
        cancellables.subscribe(to: self)
    }
    
    public func subscribe<S: Subscriber>(_ subscriber: S, storeIn cancellables: Cancellables) where S.Input == Output, S.Failure == Failure {
        cancellables.subscribe(subscriber, to: self)
    }
    
    public func subscribe<S: Subject>(_ subject: S, storeIn cancellables: Cancellables) where S.Output == Output, S.Failure == Failure {
        cancellables.subscribe(subject, to: self)
    }
}

extension Publisher {
    public func sink(
        storeIn cancellables: Cancellables,
        receiveValue: @escaping (Result<Output, Failure>) -> Void
    ) {
        toResultPublisher()
            .handleOutput(receiveValue)
            .subscribe(storeIn: cancellables)
    }
}

extension Publisher where Failure == Never {
    public func sink(
        storeIn cancellables: Cancellables,
        receiveValue: @escaping (Output) -> Void
    ) {
        handleOutput(receiveValue)
            .subscribe(storeIn: cancellables)
    }
}
