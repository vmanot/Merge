//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swift

extension Publisher {
    /// Transforms all elements and errors from the upstream publisher to a `Result`.
    public func toResultPublisher() -> Publishers.Catch<Publishers.Map<Self, Result<Output, Failure>>, Just<Result<Output, Failure>>> {
        map(Result.success).catch {
            Just(.failure($0))
        }
    }
    
    public func printOnError() -> Publishers.HandleEvents<Self> {
        handleError({ Swift.print($0) })
    }
}

extension Publisher {
    public func succeeds() -> AnyPublisher<Bool, Never> {
        map({ _ in true })
            .reduce(true, { $0 && $1 })
            .catch({ _ in Just(false) })
            .eraseToAnyPublisher()
    }
    
    public func fails() -> AnyPublisher<Bool, Never> {
        map({ _ in false })
            .reduce(false, { $0 && $1 })
            .catch({ _ in Just(true) })
            .eraseToAnyPublisher()
    }
}
