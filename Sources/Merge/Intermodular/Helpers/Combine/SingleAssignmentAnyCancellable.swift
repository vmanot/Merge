//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Combine
import Swift

public final class SingleAssignmentAnyCancellable: Cancellable, @unchecked Sendable {
    private let lock = OSUnfairLock()
    
    private var _isCanceled: Bool?
    private var base: AnyCancellable?
    
    public var isCanceled: Bool {
        lock.withCriticalScope {
            if let _isCanceled {
                return _isCanceled
            } else {
                return base == nil
            }
        }
    }
    
    public init() {
        
    }
    
    public func set<C: Cancellable>(_ base: C) {
        lock.withCriticalScope {
            guard !(_isCanceled == true) else {
                base.cancel()
                
                return
            }
            
            self.base = .init(base)
        }
    }
    
    public func cancel() {
        lock.withCriticalScope {
            guard !(_isCanceled == true) else {
                assertionFailure()
                
                return
            }
            
            self.base?.cancel()
            self.base = nil
            
            _isCanceled = true
        }
    }
}
