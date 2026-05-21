//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public protocol _CommandLineToolArgumentValueConvertible { var argumentValue: String { get } }

public protocol _CommandLineToolOptionKeyConvertible {
    var conversion: _CommandLineToolOptionKeyConversion { get }
    var name: String { get }
}

public protocol _CommandLineToolEnvironmentVariableValue { var environmentVariableStringValue: String? { get } }

extension CLT {
    public typealias ArgumentValueConvertible = _CommandLineToolArgumentValueConvertible
    public typealias OptionKeyConvertible = _CommandLineToolOptionKeyConvertible
    public typealias EnvironmentVariableValue = _CommandLineToolEnvironmentVariableValue
}

extension Never: CLT.ArgumentValueConvertible { public var argumentValue: String { fatalError(.abstract) } }

extension CLT.ArgumentValueConvertible { public var argumentValue: String { String(describing: self) } }

extension CLT.ArgumentValueConvertible where Self: RawRepresentable { public var argumentValue: String { String(describing: rawValue) } }

extension Optional: CLT.ArgumentValueConvertible where Wrapped: CLT.ArgumentValueConvertible {
    public var argumentValue: String {
        self?.argumentValue ?? ""
    }
}

extension Bool: CLT.ArgumentValueConvertible { }
extension Int: CLT.ArgumentValueConvertible { }
extension String: CLT.ArgumentValueConvertible { }

extension URL: CLT.ArgumentValueConvertible { public var argumentValue: String { path } }

extension CLT.OptionKeyConvertible { public var conversion: _CommandLineToolOptionKeyConversion { name.count > 1 ? .doubleHyphenPrefixed : .hyphenPrefixed } }

extension Optional: CLT.OptionKeyConvertible where Wrapped: CLT.OptionKeyConvertible {
    public var name: String {
        guard let self else {
            fatalError(.impossible)
        }

        return self.name
    }

    public var conversion: _CommandLineToolOptionKeyConversion {
        if let self {
            self.conversion
        } else {
            name.count > 1 ? .doubleHyphenPrefixed : .hyphenPrefixed
        }
    }
}

extension Optional: CLT.EnvironmentVariableValue where Wrapped: CLT.EnvironmentVariableValue { public var environmentVariableStringValue: String? { self?.environmentVariableStringValue } }

extension Bool: CLT.EnvironmentVariableValue { public var environmentVariableStringValue: String? { String(describing: self) } }

extension Int: CLT.EnvironmentVariableValue { public var environmentVariableStringValue: String? { String(self) } }

extension String: CLT.EnvironmentVariableValue { public var environmentVariableStringValue: String? { self } }

extension URL: CLT.EnvironmentVariableValue { public var environmentVariableStringValue: String? { path } }
