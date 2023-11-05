//
// Copyright (c) Vatsal Manot
//

import Combine
import ObjectiveC

/// A type that provides a `Cancellables` instance.
public protocol _CancellablesProviding {
    var cancellables: Cancellables { get }
}

// MARK: - Implementation

private var cancellables_objcAssociationKey: UInt = 0

extension _CancellablesProviding where Self: AnyObject {
    public var cancellables: Cancellables {
        objc_sync_enter(self)
        
        defer {
            objc_sync_exit(self)
        }
        
        if let result = objc_getAssociatedObject(self, &cancellables_objcAssociationKey) as? Cancellables {
            return result
        } else {
            let result = Cancellables()
            
            objc_setAssociatedObject(self, &cancellables_objcAssociationKey, result, .OBJC_ASSOCIATION_RETAIN)
            
            return result
        }
    }
}
