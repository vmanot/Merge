//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Subscriptions {
    public final class AddCancellable<Base: Subscription>: Subscription {
        private let mutex = OSUnfairLock()
        private let base: Base
        private var cancellable: Cancellable?
        
        public init(base: Base, cancellable: Cancellable) {
            self.base = base
            self.cancellable = cancellable
        }
        
        public func request(_ demand: Subscribers.Demand) {
            base.request(demand)
        }
        
        public func cancel() {
            mutex.withCriticalScope {
                base.cancel()
                
                cancellable?.cancel()
                cancellable = nil
            }
        }
    }
}

// MARK: - API
 
extension Subscription {
    public func add(_ cancellable: Cancellable) -> Subscription {
        Subscriptions.AddCancellable(base: self, cancellable: cancellable)
    }
}
