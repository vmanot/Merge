//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift
import Swallow

public protocol  _CommandLineToolOptionKeyConvertible {
    var conversion: _CommandLineToolOptionKeyConversion { get }
    var name: String { get }
}

extension CLT {
    public typealias OptionKeyConvertible = _CommandLineToolOptionKeyConvertible
}

extension CLT.OptionKeyConvertible {
    public var conversion: _CommandLineToolOptionKeyConversion {
        name.count > 1 ? .doubleHyphenPrefixed : .hyphenPrefixed
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
    
    public var conversion: _CommandLineToolOptionKeyConversion {
        if let self {
            self.conversion
        } else {
            name.count > 1 ? .doubleHyphenPrefixed : .hyphenPrefixed
        }
    }
}
