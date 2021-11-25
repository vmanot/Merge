//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swallow
import SwiftUI

/// A thread-safe collection suitable for storing instanes of `AnyCancellable`.
public final class Cancellables: Cancellable {
    private var queue = DispatchQueue(label: "com.vmanot.Merge.Cancellables.maintenance")
    private var cancellables: Set<AnyCancellable> = []
    
    public init() {
        
    }
    
    public func insert(_ cancellable: AnyCancellable) {
        queue.async {
            cancellable.store(in: &self.cancellables)
        }
    }
    
    public func insert<C: Cancellable>(_ cancellable: C) {
        queue.async {
            cancellable.store(in: &self.cancellables)
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
        
        publisher
            .handleEvents(
                receiveCompletion: { [weak self] _ in self?.remove(cancellable) },
                receiveCancel: { [weak self] in self?.remove(cancellable) }
            )
            .receive(subscriber: subscriber)
    }
}

// MARK: - API -

extension Cancellables {
    public func store(@ArrayBuilder<Cancellable> cancellables: () -> [Cancellable]) {
        cancellables().forEach({ $0.store(in: self) })
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
}

extension Publisher where Failure == Never {
    public func sink(
        in cancellables: Cancellables,
        receiveValue: @escaping (Output) -> Void
    ) {
        handleOutput(receiveValue)
            .subscribe(in: cancellables)
    }
}

// MARK: - Conformances -

extension Cancellables: ExpressibleByArrayLiteral {
    public convenience init(arrayLiteral elements: AnyCancellable...) {
        self.init()
        
        self.cancellables = .init(elements)
    }
}

// MARK: - Auxiliary Implementation -

extension Cancellables {
    fileprivate struct EnvironmentKey: SwiftUI.EnvironmentKey {
        static let defaultValue = Cancellables()
    }
}

extension EnvironmentValues {
    public var cancellables: Cancellables {
        get {
            self[Cancellables.EnvironmentKey.self]
        } set {
            self[Cancellables.EnvironmentKey.self] = newValue
        }
    }
}
