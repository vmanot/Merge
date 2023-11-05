//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift

extension Publisher {
    public func breakpoint(_ trap: Bool) -> Publishers.Breakpoint<Self> {
        breakpoint(
            receiveSubscription: { _ in trap },
            receiveOutput: { _ in trap },
            receiveCompletion: { _ in trap }
        )
    }
}
