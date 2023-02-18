//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

@propertyWrapper
public struct UncheckedSendable<Value>: @unchecked Sendable {
    public let wrappedValue: Value
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public init(initialValue: Value) {
        self.wrappedValue = initialValue
    }
    
    public init(_ value: Value) {
        self.init(wrappedValue: value)
    }
}
