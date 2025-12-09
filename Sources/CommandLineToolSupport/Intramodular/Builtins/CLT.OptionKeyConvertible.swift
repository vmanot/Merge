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
        var optionKey: _CommandLineToolOptionKey { get }
    }
}

extension Optional: CLT.OptionKeyConvertible where Wrapped: CLT.OptionKeyConvertible {
    public var optionKey: _CommandLineToolOptionKey {
        if let self {
            self.optionKey
        } else {
            fatalError(.impossible) // flags with nil should never try to call this.
        }
    }
}
