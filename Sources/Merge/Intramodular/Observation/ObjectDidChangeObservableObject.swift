//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

/// A type of object with a publisher that emits after the object has changed.
public protocol ObjectDidChangeObservableObject: ObservableObject {
    associatedtype ObjectDidChangePublisher: Publisher = _ObjectDidChangePublisher where ObjectDidChangePublisher.Failure == Never
    
    /// A publisher that emits _after_ the object has changed.
    var objectDidChange: ObjectDidChangePublisher { get }
}

// MARK: - Implementation -

private var _objectDidChange_objcAssociationKey: UInt = 0

extension ObjectDidChangeObservableObject where ObjectDidChangePublisher == _ObjectDidChangePublisher {
    public var objectDidChange: ObjectDidChangePublisher {
        objc_sync_enter(self)

        defer {
            objc_sync_exit(self)
        }

        if let result = objc_getAssociatedObject(self, &_objectDidChange_objcAssociationKey) as? ObjectDidChangePublisher {
            return result
        } else {
            let publisher = ObjectDidChangePublisher()
            
            objc_setAssociatedObject(
                self,
                &_objectDidChange_objcAssociationKey,
                publisher,
                .OBJC_ASSOCIATION_RETAIN
            )
            
            assert((objc_getAssociatedObject(self, &_objectDidChange_objcAssociationKey) as? ObjectDidChangePublisher) != nil)
            
            return publisher
        }
    }
}

// MARK: - Auxiliary

public final class _ObjectDidChangePublisher: Publisher, Subject, @unchecked Sendable {
    public typealias Output = Void
    public typealias Failure = Never
    
    private let lock = OSUnfairLock()
    private let base = PassthroughSubject<Void, Never>()
    
    public init() {
        
    }
    
    public func receive(
        subscriber: some Subscriber<Output, Failure>
    ) {
        lock.withCriticalScope {
            base.receive(subscriber: subscriber)
        }
    }

    public func send(_ value: Void) {
        lock.withCriticalScope {
            base.send(())
        }
    }
    
    public func send() {
        self.send(())
    }
    
    public func send(completion: Subscribers.Completion<Failure>) {
        switch completion {
            case .finished:
                assertionFailure()
        }
    }
    
    public func send(subscription: Subscription) {
        base.send(subscription: subscription)
    }
}

extension ObservableObject {
    public func _makeObjectDidChangePublisher() -> AnyPublisher<Void, Never> {
        if let _self = self as? (any ObjectDidChangeObservableObject) {
            return _self._opaque_objectDidChange
        } else {
            return objectWillChange
                .receive(on: DispatchQueue.main)
                .mapTo(())
                .eraseToAnyPublisher()
        }
    }
}

extension ObjectDidChangeObservableObject {
    public var _opaque_objectDidChange: AnyPublisher<Void, Never> {
        objectDidChange.mapTo(()).eraseToAnyPublisher()
    }
}

// MARK: - Deprecated

public typealias _ObservableObjectX = ObjectDidChangeObservableObject
