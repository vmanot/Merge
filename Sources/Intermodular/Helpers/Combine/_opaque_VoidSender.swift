//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

public protocol _opaque_VoidSender {
    func send()
}

// MARK: - Conformances -

extension CurrentValueSubject: _opaque_VoidSender where Output == Void {
    
}

extension ObservableObjectPublisher: _opaque_VoidSender {
    
}

extension PassthroughSubject: _opaque_VoidSender where Output == Void {
    
}

// MARK: - Helpers -

extension Publisher where Failure == Never {
    @inlinable
    public func publish(to publisher: _opaque_VoidSender) -> Publishers.HandleEvents<Self> {
        handleEvents(receiveOutput: { _ in publisher.send() })
    }
    
    @inlinable
    public func publish(to object: _opaque_ObservableObject) -> Publishers.HandleEvents<Self> {
        handleEvents(receiveOutput: { _ in try! object._opaque_objectWillChange_send() })
    }
}

extension ObservableObjectPublisher {
    @inlinable
    public func publish(to publisher: _opaque_VoidSender) -> Publishers.HandleEvents<ObservableObjectPublisher> {
        handleEvents(receiveOutput: { _ in publisher.send() })
    }
}
