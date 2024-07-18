//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Combine.Cancellable {
    public func eraseToAnyCancellable() -> Combine.AnyCancellable {
        Combine.AnyCancellable(self)
    }
}

extension _Concurrency.Task: Combine.Cancellable {
    
}
