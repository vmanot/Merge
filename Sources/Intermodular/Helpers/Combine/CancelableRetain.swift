//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift

public final class CancellableRetain<Value>: Cancellable {
    private var value: Value?
    
    public init(_ value: Value) {
        self.value = value
    }
    
    public func cancel() {
        value = nil
    }
}
