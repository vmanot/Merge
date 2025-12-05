//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public protocol _CommandLineToolParameterProtocol: PropertyWrapper {
    
}

@propertyWrapper
public struct _CommandLineToolParameter<WrappedValue>: _CommandLineToolParameterProtocol {
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

extension CommandLineTool {
    public typealias Parameter<T> = _CommandLineToolParameter<T>
}
