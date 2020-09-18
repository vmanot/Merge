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

extension ObservableObjectPublisher {
    @inlinable
    public func publish(to publisher: _opaque_VoidSender) -> some Publisher {
        handleOutput({ publisher.send() })
    }
}
