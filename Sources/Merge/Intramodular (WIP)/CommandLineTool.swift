//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

open class AnyCommandLineTool {
    public init() {
        
    }
}

/// A type that wraps a command line tool.
public protocol CommandLineTool: AnyCommandLineTool {
    typealias Parameter<T> = _CommandLineToolParameter<T>
}

extension AnyCommandLineTool: CommandLineTool {
    
}

public enum CommandLineTools {
    
}

public typealias CLT = CommandLineTools


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
