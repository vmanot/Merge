//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Future {
    public static func just(_ value: Result<Output, Failure>) -> Self {
        return .init { attemptToFulfill in
            attemptToFulfill(value)
        }
    }
    
    public func sinkResult(_ receiveCompletion: @escaping (Result<Output, Failure>) -> ()) -> AnyCancellable {
        sink(receiveCompletion: { completion in
            switch completion {
                case .finished:
                    break
                case .failure(let error):
                    receiveCompletion(.failure(error))
            }
        }, receiveValue: { value in
            receiveCompletion(.success(value))
        })
    }
}
