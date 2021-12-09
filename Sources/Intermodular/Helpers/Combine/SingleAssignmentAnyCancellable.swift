//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Combine
import Swift

public final class SingleAssignmentAnyCancellable: Cancellable {
    private let lock = OSUnfairLock()
    
    private var base: AnyCancellable?
    
    public init() {
        
    }
    
    public func set<C: Cancellable>(_ base: C) {
        lock.withCriticalScope {
            self.base = .init(base)
        }
    }
    
    public func cancel() {
        lock.withCriticalScope {
            self.base?.cancel()
            self.base = nil
        }
    }
}
