//
// Copyright (c) Vatsal Manot
//

import Combine
import ObjectiveC

/// A type that holds cancellables.
public protocol CancellablesHolder {
    var cancellables: Cancellables { get }
}

// MARK: - Implementation -

private var cancellables_objcAssociationKey: Void = ()

extension CancellablesHolder where Self: AnyObject {
    public var cancellables: Cancellables {
        if let result = objc_getAssociatedObject(self, &cancellables_objcAssociationKey) as? Cancellables {
            return result
        } else {
            let result = Cancellables()
            
            objc_setAssociatedObject(self, &cancellables_objcAssociationKey, result, .OBJC_ASSOCIATION_RETAIN)
            
            return result
        }
    }
}
