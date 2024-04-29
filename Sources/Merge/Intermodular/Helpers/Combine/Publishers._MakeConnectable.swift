//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

extension Publishers {
    public final class _MakeConnectable<Base: Publisher>: ConnectablePublisher, @unchecked Sendable {
        public typealias Output = Base.Output
        public typealias Failure = Base.Failure
        
        private var base: Base
        private let subject = PassthroughSubject<Base.Output, Base.Failure>()
        private var connection: Cancellable?
        private var lock = NSLock()
        
        // The isConnected property is private and thread-safe accessed via a computed property
        private var _isConnected: Bool = false
        
        public var isConnected: Bool {
            get {
                lock.lock()
                
                defer {
                    lock.unlock()
                }
                
                return _isConnected
            }
            set {
                lock.lock()
                
                _isConnected = newValue
                
                lock.unlock()
            }
        }
        
        public init(_ base: Base) {
            self.base = base
        }
        
        public func receive<S: Subscriber>(
            subscriber: S
        ) where Base.Failure == S.Failure, Base.Output == S.Input {
            subject.subscribe(subscriber)
        }
        
        public func connect() -> Cancellable {
            lock.lock()
            
            defer {
                lock.unlock()
            }
            
            if _isConnected {
                return AnyCancellable {}
            }
            
            _isConnected = true
            
            let subscription = base.subscribe(subject)
            
            let connection = AnyCancellable {
                self.lock.lock()
                self._isConnected = false
                self.lock.unlock()
                subscription.cancel()
            }
            
            self.connection = connection
            
            return connection
        }
    }
}

extension Publishers._MakeConnectable {
    public func _performIfConnected(_ operation: () throws -> Void) rethrows -> Void {
        lock.lock()
        
        defer {
            lock.unlock()
        }
        
        guard _isConnected else {
            return
        }
        
        try operation()
    }
}

// MARK: - Conformances

extension Publishers._MakeConnectable: Initiable where Base: Initiable {
    public convenience init() {
        self.init(Base())
    }
}

extension Publishers._MakeConnectable: Subject where Base: Subject {
    public func send(_ value: Base.Output) {
        lock.lock()
        
        defer {
            lock.unlock()
        }
        
        guard _isConnected else {
            return
        }
        
        base.send(value)
    }
    
    public func send(completion: Subscribers.Completion<Base.Failure>) {
        base.send(completion: completion)
    }
    
    public func send(subscription: any Subscription) {
        base.send(subscription: subscription)
    }
}

// MARK: - Supplementary

extension Publisher {
    public func _makeConnectable() -> Publishers._MakeConnectable<Self> {
        .init(self)
    }
}
