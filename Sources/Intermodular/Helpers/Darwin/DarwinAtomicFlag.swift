//
// Copyright (c) Vatsal Manot
//

import Darwin
import Swallow

public struct DarwinAtomicFlag {
    @usableFromInline
    var value: atomic_flag
    
    public init() {
        self.value = .init()
    }

    @inlinable
    public mutating func testAndSet(withOrder order: DarwinAtomicOperationMemoryOrder) -> Bool {
        return atomic_flag_test_and_set_explicit(&value, order.rawValue)
    }

    @inlinable
    public mutating func testAndSet() -> Bool {
        return atomic_flag_test_and_set(&value)
    }

    @inlinable
    public mutating func clear(withOrder order: DarwinAtomicOperationMemoryOrder) {
        atomic_flag_clear_explicit(&value, order.rawValue)
    }

    @inlinable
    public mutating func clear() {
        atomic_flag_clear(&value)
    }
}
