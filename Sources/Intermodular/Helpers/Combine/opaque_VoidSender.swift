//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

public protocol _opaque_VoidSender {
    func send()
}

// MARK: - Auxiliary Implementation -

extension CurrentValueSubject: _opaque_VoidSender where Output == Void {
    
}

extension ObservableObjectPublisher: _opaque_VoidSender {
    
}

extension PassthroughSubject: _opaque_VoidSender where Output == Void {
    
}
