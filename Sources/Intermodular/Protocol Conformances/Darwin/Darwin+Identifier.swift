//
// Copyright (c) Vatsal Manot
//

import Compute
import Swallow

public struct OSUnfairAtomicIdentifier: Identifier {
    public let value: UInt64
    
    public init(_ value: UInt64) {
        self.value = value
    }
}

public class OSUnfairAtomicIdentifierGenerator: MutexProtected {
    public let mutex = OSUnfairLock()
    
    public var current: UInt64 = 0
    
    public func next() -> OSUnfairAtomicIdentifier {
        return withMutexProtectedCriticalScope {
            defer {
                current &+= 1
            }
            
            return .init(current)
        }
    }
}
