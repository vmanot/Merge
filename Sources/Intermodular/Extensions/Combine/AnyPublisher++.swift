//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension AnyPublisher {
    public static func just(_ output: Output) -> Self {
        Just(output)
            .setFailureType(to: Failure.self)
            .eraseToAnyPublisher()
    }
    
    public static func failure(_ failure: Failure) -> Self {
        Result.Publisher(failure).eraseToAnyPublisher()
    }
    
    public static func empty(completeImmediately: Bool = true) -> Self {
        Empty(completeImmediately: completeImmediately)
            .setFailureType(to: Failure.self)
            .eraseToAnyPublisher()
    }
}
