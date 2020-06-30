//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

public struct AnySubscription: Subscription {
    public let combineIdentifier = CombineIdentifier()
    
    private let cancellable: Cancellable
    private let onRequest: (Subscribers.Demand) -> ()
    
    public init(
        _ cancellable: Cancellable,
        onRequest: @escaping (Subscribers.Demand) -> () = { _ in }
    ) {
        self.cancellable = cancellable
        self.onRequest = onRequest
    }
    
    public func cancel() {
        cancellable.cancel()
    }
    
    public func request(_ demand: Subscribers.Demand) {
        onRequest(demand)
    }
}
