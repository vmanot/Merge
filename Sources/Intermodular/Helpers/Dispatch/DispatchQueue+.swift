//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift

extension Publisher {
    public func receiveOnMainQueue() -> Publishers.ReceiveOn<Self, DispatchQueue> {
        receive(on: DispatchQueue.main)
    }
}
