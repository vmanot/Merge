//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

open class SingleAssignmentAnyCancellable: Cancellable {
    private let lock = OSUnfairLock()
    
    private var base: AnyCancellable?
    private var isCancelled: Bool = false
    
    public init() {
        
    }
    
    public func set<C: Cancellable>(_ base: C) {
        lock.withCriticalScope {
            guard !isCancelled else {
                base.cancel()
                return
            }
            
            self.base = .init(base)
        }
    }
    
    public func cancel() {
        lock.withCriticalScope {
            guard !isCancelled else {
                return
            }
            
            base = nil
            
            isCancelled = true
        }
    }
}
