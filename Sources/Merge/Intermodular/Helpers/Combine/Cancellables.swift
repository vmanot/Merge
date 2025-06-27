//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swallow
import SwiftUI

/// A thread-safe collection suitable for storing instances of `AnyCancellable`.
public final class Cancellables: @unchecked Sendable, Cancellable {
    private var queue = DispatchQueue(label: "com.vmanot.Merge.Cancellables")
    private var cancellables: Set<AnyCancellable> = []
    
    public init() {
        
    }
    
    /// Adds the given cancellable object to the set.
    public func insert(_ cancellable: AnyCancellable) {
        queue.async {
            cancellable.store(in: &self.cancellables)
        }
    }
    
    /// Adds the given cancellable object to the set.
    public func insert<C: Cancellable>(
        _ cancellable: C
    ) {
        queue.async {
            cancellable.store(in: &self.cancellables)
        }
    }
    
    /// Adds the given cancellable object to the set.
    public func insert(
        @ArrayBuilder cancellables: () -> [any Cancellable]
    ) {
        let cancellables = cancellables()
        
        queue.async {
            cancellables.forEach { cancellable in
                cancellable.store(in: &self.cancellables)
            }
        }
    }
    
    /// Removes the specified cancellable object from the set.
    public func remove(_ cancellable: AnyCancellable) {
        queue.async {
            self.cancellables.remove(cancellable)
        }
    }
    
    /// Cancels and removes all cancellable objects from within the set.
    public func cancel() {
        queue.async {
            self.cancellables.forEach({ $0.cancel() })
            self.cancellables.removeAll()
        }
    }
}

extension Cancellables {
    fileprivate func subscribe<P: Publisher>(to publisher: P) {
        let innerCancellable = SingleAssignmentAnyCancellable()
        let cancellable = AnyCancellable(innerCancellable)
        
        insert(cancellable)
        
        let cancelOrCompletionHandler =
            publisher
            .handleCancelOrCompletion { [weak self, weak cancellable] _ in
                guard let cancellable = cancellable else {
                    return
                }
                
                self?.remove(cancellable)
            }
            .sink()
        
        queue.sync {
            innerCancellable.set(cancelOrCompletionHandler)
        }
    }
    
    fileprivate func subscribe<S: Subject, P: Publisher>(_ subject: S, to publisher: P) where S.Output == P.Output, S.Failure == P.Failure {
        let innerCancellable = SingleAssignmentAnyCancellable()
        let cancellable = AnyCancellable(innerCancellable)
        
        insert(cancellable)
        
        let cancelOrCompletionHandler =
            publisher
            .handleCancelOrCompletion { [weak self, weak cancellable] _ in
                guard let cancellable = cancellable else {
                    return
                }
                
                self?.remove(cancellable)
            }
            .subscribe(subject)
        
        queue.sync {
            innerCancellable.set(cancelOrCompletionHandler)
        }
    }
    
    public func subscribe<S: Subscriber, P: Publisher>(_ subscriber: S, to publisher: P) where S.Input == P.Output, S.Failure == P.Failure {
        let cancellable = AnyCancellable(CancellableRetain(subscriber))
        
        insert(cancellable)
        
        publisher
            .handleEvents(
                receiveCompletion: { [weak self] _ in self?.remove(cancellable) },
                receiveCancel: { [weak self] in self?.remove(cancellable) }
            )
            .receive(subscriber: subscriber)
    }
}

// MARK: - API

extension Cancellables {
    public func store(@ArrayBuilder cancellables: () -> [Cancellable]) {
        cancellables().forEach({ $0.store(in: self) })
    }
    
    public func store<T: Cancellable>(
        _ cancellable: () -> T
    ) {
        cancellable().store(in: self)
    }
}

extension AnyCancellable {
    public func store(in cancellables: Cancellables) {
        cancellables.insert(self)
    }
}

extension Cancellable {
    @discardableResult
    public func store(in cancellables: Cancellables) -> Self {
        cancellables.insert(self)
        
        return self
    }
}

extension Publisher {
    public func subscribe(in cancellables: Cancellables) {
        cancellables.subscribe(to: self)
    }
    
    public func subscribe<S: Subscriber>(_ subscriber: S, in cancellables: Cancellables) where S.Input == Output, S.Failure == Failure {
        cancellables.subscribe(subscriber, to: self)
    }
    
    public func subscribe<S: Subject>(_ subject: S, in cancellables: Cancellables) where S.Output == Output, S.Failure == Failure {
        cancellables.subscribe(subject, to: self)
    }
}

extension Publisher {
    public func sinkResult(
        in cancellables: Cancellables,
        receiveValue: @escaping (Result<Output, Failure>) -> Void
    ) {
        toResultPublisher()
            .handleOutput(receiveValue)
            .subscribe(in: cancellables)
    }
    
    public func sink(
        in cancellables: Cancellables,
        receiveValue: @escaping (Output) -> Void
    ) where Failure == Never {
        handleOutput(receiveValue)
            .subscribe(in: cancellables)
    }
    
    public func sink(
        in cancellables: Cancellables,
        receiveValue: @escaping (Output) -> Void,
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> ()
    ) where Failure == Never {
        handleOutput(receiveValue)
            .handleCompletion(receiveCompletion)
            .subscribe(in: cancellables)
    }
}

// MARK: - Conformances

extension Cancellables: ExpressibleByArrayLiteral {
    public convenience init(arrayLiteral elements: AnyCancellable...) {
        self.init()
        
        self.cancellables = .init(elements)
    }
}

// MARK: - Auxiliary

extension Cancellables {
    fileprivate struct EnvironmentKey: SwiftUI.EnvironmentKey {
        static let defaultValue = Cancellables()
    }
}

extension EnvironmentValues {
    public var cancellables: Cancellables {
        get {
            self[Cancellables.EnvironmentKey.self]
        }
        set {
            self[Cancellables.EnvironmentKey.self] = newValue
        }
    }
}
