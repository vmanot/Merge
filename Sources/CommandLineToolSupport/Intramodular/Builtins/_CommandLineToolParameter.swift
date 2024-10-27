//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

@propertyWrapper
public struct _CommandLineToolParameter<WrappedValue> {
    var _wrappedValue: WrappedValue
    
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            _wrappedValue = newValue
        }
    }
    
    public init(wrappedValue: WrappedValue) {
        self._wrappedValue = wrappedValue
    }
}
