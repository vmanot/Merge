//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

extension Operation {
    /// Creates a task that represents this `Operation`.
    public func convertToTask() -> AnyTask<Void, Never> {
        let result = PassthroughTask<Void, Never>()
        
        completionBlock = {
            result.send(.success(()))
        }
        
        return result
            .handleEvents(receiveStart: { self.start() })
            .eraseToAnyTask()
    }
}
