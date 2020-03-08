//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publisher {
    public func then<P: Publisher>(_ publisher: P) -> AnyPublisher<P.Output, Error> {
        eraseError()
            .flatMap({ _ in publisher.eraseError() })
            .eraseToAnyPublisher()
    }
    
    public func then<P: Publisher>(deferred createPublisher: @autoclosure @escaping () -> P) -> AnyPublisher<P.Output, Error> {
        then(Deferred(createPublisher: createPublisher))
    }
    
    public func then<P: Publisher>(deferred createPublisher: @escaping () -> P) -> AnyPublisher<P.Output, Error> {
        then(Deferred(createPublisher: createPublisher))
    }
    
    public func then(_ action: @escaping () -> Void) -> Publishers.Map<Self, Output> {
        map { output -> Output in
            action()
            return output
        }
    }
}

extension Publisher where Failure == Never {
    public func then<P: Publisher>(
        _ publisher: P
    ) -> Publishers.FlatMap<P, Self> where P.Failure == Never {
        flatMap({ _ in publisher })
    }
}
