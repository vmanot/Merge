//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

private enum UnwrapError: Error {
    case this
}
 
extension Publisher where Failure == Never {
    public func unwrap<Wrapped>() -> Publishers.TryMap<Self, Wrapped> where Optional<Wrapped> == Output {
        tryMap { value -> Wrapped in
            guard let value = value else {
                throw UnwrapError.this
            }
            
            return value
        }
    }
}

extension Publisher where Failure == Error {
    public func unwrap<Wrapped>() -> Publishers.TryMap<Self, Wrapped> where Optional<Wrapped> == Output {
        tryMap { value -> Wrapped in
            guard let value = value else {
                throw UnwrapError.this
            }
            
            return value
        }
    }
}
