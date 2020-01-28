//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publisher {
    public func join<P: Publisher, S: Sequence>(_ publishers: S) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Failure, S.Element == P {
        publishers.reduce(eraseToAnyPublisher()) { result, next in
            result.flatMap { output in
                Publishers.Concatenate(
                    prefix: Just(output).setFailureType(to: Failure.self),
                    suffix: next
                )
            }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

extension Collection where Element: Publisher {
    public func join() -> AnyPublisher<Element.Output, Element.Failure> {
        if let first = first {
            return first.join(dropFirst()).eraseToAnyPublisher()
        } else {
            return Empty().setFailureType(to: Element.Failure.self).eraseToAnyPublisher()
        }
    }
}
