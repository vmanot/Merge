//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Published {
    private class PublishedWrapper {
        @Published<Value> private(set) var value: Value
        
        init(_ value: Published<Value>) {
            _value = value
        }
    }
    
    @_spi(Internal)
    public var _wrappedValue: Value {
        PublishedWrapper(self).value
    }
}
