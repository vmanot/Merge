//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publisher {
    /// Dumps the the publisher's output's contents using its mirror.
    public func dump() -> Publishers.HandleEvents<Self> {
        handleOutput({ Swift.dump($0) })
    }
}
