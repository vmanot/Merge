//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Cancellable {
    public func eraseToAnyCancellable() -> AnyCancellable {
        AnyCancellable(self)
    }
}

extension Task: Cancellable {
    
}
