//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

public protocol opaque_VoidSender {
    func send()
}

// MARK: - Auxiliary Implementation -

extension CurrentValueSubject: opaque_VoidSender where Output == Void {
    
}

extension ObservableObjectPublisher: opaque_VoidSender {
    
}

extension PassthroughSubject: opaque_VoidSender where Output == Void {
    
}
