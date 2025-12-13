//
//  CLT.OptionKeyConvertible.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/10.
//

import Foundation
import Swift
import Swallow

extension CLT {
    public protocol OptionKeyConvertible {
        var conversion: _CommandLineToolOptionKeyConversion? { get }
        var name: String { get }
    }
}

extension CLT.OptionKeyConvertible {
    public var conversion: _CommandLineToolOptionKeyConversion? {
        nil
    }
}

extension Optional: CLT.OptionKeyConvertible where Wrapped: CLT.OptionKeyConvertible {
    public var name: String {
        if let self {
            self.name
        } else {
            fatalError(.impossible) // flags with nil should never try to call this.
        }
    }
    
    public var conversion: _CommandLineToolOptionKeyConversion? {
        if let self {
            return self.conversion
        }
        return nil
    }
}
