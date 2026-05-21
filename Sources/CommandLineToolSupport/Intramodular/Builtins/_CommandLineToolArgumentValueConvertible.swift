//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift
import Swallow

/// A type that can represent the raw value of an environment variable to be passed in a command invocation.
public protocol _CommandLineToolArgumentValueConvertible {
    var argumentValue: String { get }
}

extension CLT {
    public typealias ArgumentValueConvertible = _CommandLineToolArgumentValueConvertible
}

extension Never: CLT.ArgumentValueConvertible {
    public var argumentValue: String {
        fatalError(.abstract)
    }
}

extension CLT.ArgumentValueConvertible {
    public var argumentValue: String {
        String(describing: self)
    }
}

extension CLT.ArgumentValueConvertible where Self: RawRepresentable {
    public var argumentValue: String {
        String(describing: rawValue)
    }
}

extension Optional: CLT.ArgumentValueConvertible where Wrapped: CLT.ArgumentValueConvertible {
    public var argumentValue: String {
        if let value = self {
            return value.argumentValue
        }
        
        return ""
    }
}

extension Bool: CLT.ArgumentValueConvertible {
    
}

extension Int: CLT.ArgumentValueConvertible {
    
}

extension String: CLT.ArgumentValueConvertible {
    
}

extension URL: CLT.ArgumentValueConvertible {
    public var argumentValue: String {
        path
    }
}
