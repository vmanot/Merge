//
// Copyright (c) Vatsal Manot
//

import Swift

public actor _AsyncValueBox<Value>: Sendable {
    public var value: Value
    
    public init(value: Value) {
        self.value = value
    }
    
    public func mutate(_ body: (inout Value) -> Void) {
        body(&value)
    }
}
