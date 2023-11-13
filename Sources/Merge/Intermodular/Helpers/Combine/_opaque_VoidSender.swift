//
// Copyright (c) Vatsal Manot
//

import Combine
import Runtime

public protocol _opaque_VoidSender: AnyObject {
    func send()
}

// MARK: - Conformances

extension CurrentValueSubject: _opaque_VoidSender where Output == Void {
    
}

extension ObservableObjectPublisher: _opaque_VoidSender {
    
}

extension PassthroughSubject: _opaque_VoidSender where Output == Void {
    
}

// MARK: - Helpers

extension Publisher where Failure == Never {
    @inlinable
    public func publish(to object: _opaque_ObservableObject) -> Publishers.HandleEvents<Self> {
        if let object = object as? (_opaque_ObservableObject & AnyObject) {
            return handleEvents(receiveOutput: { [weak object] _ in
                try! object?._opaque_objectWillChange_send()
            })
        } else {
            assertionFailure()
            
            return handleEvents(receiveOutput: { _ in
                try! object._opaque_objectWillChange_send()
            })
        }
    }
    
    @inlinable
    public func publish<T: ObservableObject>(
        to object: T
    ) -> Publishers.HandleEvents<Self> where T.ObjectWillChangePublisher == Combine.ObservableObjectPublisher {
        handleEvents(receiveOutput: { [weak object] _ in
            object?.objectWillChange.send()
        })
    }
}

extension Publisher where Output == Void, Failure == Never {
    @inlinable
    public func publish(
        to publisher: _opaque_VoidSender
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(receiveOutput: { [weak publisher] _ in
            guard let publisher = publisher else {
                assertionFailure()
                
                return
            }
            
            publisher.send()
        })
    }
}

@_spi(Internal)
public func _ObservableObject_objectWillChange_send<T>(_ x: T) {
    guard let x = x as? (any ObservableObject) else {
        return
    }
    
    guard let x = (x.objectWillChange as (any Publisher)) as? _opaque_VoidSender else {
        assertionFailure()
        
        return
    }
    
    x.send()
}
