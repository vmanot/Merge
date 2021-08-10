//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publisher {
    /// Attaches an anonymous subscriber.
    public func sink() -> AnyCancellable {
        sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }
}

extension SingleOutputPublisher {
    /// Attaches a subscriber with closure-based behavior.
    public func sinkResult(
        _ receiveValue: @escaping (Result<Output, Failure>) -> ()
    ) -> AnyCancellable {
        sink(receiveCompletion: { completion in
            switch completion {
                case .finished:
                    break
                case .failure(let error):
                    receiveValue(.failure(error))
            }
        }, receiveValue: { value in
            receiveValue(.success(value))
        })
    }
}
