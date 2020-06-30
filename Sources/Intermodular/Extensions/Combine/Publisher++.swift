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
