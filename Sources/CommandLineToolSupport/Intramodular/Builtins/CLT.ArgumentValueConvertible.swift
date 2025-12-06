//
//  CLT.ArgumentValueConvertible.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/6.
//

import Foundation
import Swift
import Swallow

extension CLT {
    /// A type that can represent the raw value of an environment variable to be passed in a command invocation.
    public protocol ArgumentValueConvertible {
        var argumentValue: String { get }
    }
}

extension CLT.ArgumentValueConvertible {
    public var argumentValue: String {
        String(describing: self)
    }
}

extension CLT.ArgumentValueConvertible where Self : RawRepresentable {
    public var argumentValue: String {
        String(describing: rawValue)
    }
}

extension Optional: CLT.ArgumentValueConvertible where Wrapped: CLT.ArgumentValueConvertible {
    public var argumentValue: String {
        if let value = self {
            return value.argumentValue
        }
        
        fatalError(.abstract)
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
        path(percentEncoded: false).replacing(" ", with: "\\ ")
    }
}
