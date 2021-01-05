//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

extension OperationQueue {
    /// Add a barrier task.
    public func addBarrierTask() -> AnyTask<Void, Never> {
        let result = PassthroughTask<Void, Never>()
        
        self.addBarrierBlock {
            result.send(.success(()))
        }
        
        return result.eraseToAnyTask()
    }
}
