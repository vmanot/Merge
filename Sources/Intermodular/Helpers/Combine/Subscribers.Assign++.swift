//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift

extension Publisher {
    public func publish<Root>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on object: Root) -> Publishers.HandleEvents<Self> {
        handleOutput {
            object[keyPath: keyPath] = $0
        }
    }
    
    public func publish<Root>(to keyPath: ReferenceWritableKeyPath<Root, Output?>, on object: Root) -> Publishers.HandleEvents<Self> {
        handleOutput {
            object[keyPath: keyPath] = $0
        }
    }
}
