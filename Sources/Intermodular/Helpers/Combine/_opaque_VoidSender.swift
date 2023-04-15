//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

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
            return handleEvents(receiveOutput: { [weak object] _ in try! object?._opaque_objectWillChange_send() })
        } else {
            assertionFailure()
            
            return handleEvents(receiveOutput: { _ in try! object._opaque_objectWillChange_send() })
        }
    }
    
    @inlinable
    public func publish<T: ObservableObject>(to object: T) -> Publishers.HandleEvents<Self> where T.ObjectWillChangePublisher == Combine.ObservableObjectPublisher {
        handleEvents(receiveOutput: { [weak object] _ in object?.objectWillChange.send() })
    }
}

extension Publisher where Output == Void, Failure == Never {
    @inlinable
    public func publish(
        to publisher: _opaque_VoidSender
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(receiveOutput: { [weak publisher] _ in publisher?.send() })
    }
}
