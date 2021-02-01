//
// Copyright (c) Vatsal Manot
//

import Darwin
import Swallow

/*public struct DarwinAtomicFlag {
    var wrappedValue: atomic_flag
    
    public init() {
        self.wrappedValue = atomic_flag()
    }

    public mutating func testAndSet(withOrder order: DarwinAtomicOperationMemoryOrder) -> Bool {
        atomic_flag_test_and_set_explicit(&wrappedValue, order.rawValue)
    }

    public mutating func testAndSet() -> Bool {
        atomic_flag_test_and_set(&wrappedValue)
    }

    public mutating func clear(withOrder order: DarwinAtomicOperationMemoryOrder) {
        atomic_flag_clear_explicit(&wrappedValue, order.rawValue)
    }

    public mutating func clear() {
        atomic_flag_clear(&wrappedValue)
    }
}
*/
