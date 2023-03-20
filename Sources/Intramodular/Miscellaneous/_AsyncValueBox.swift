//
// Copyright (c) Vatsal Manot
//

import Swift

public actor _AsyncPromiseBox<Value>: Sendable {
    public var value: Value
    
    public init(_ value: Value) {
        self.value = value
    }
    
    public func withCriticalRegion<T>(
        _ body: (inout Value) -> T
    ) -> T {
        body(&value)
    }
}
