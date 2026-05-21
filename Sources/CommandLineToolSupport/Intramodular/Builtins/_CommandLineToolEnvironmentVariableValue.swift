//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

/// A type that can represent the raw value of an environment variable to be passed in a command invocation.
public protocol _CommandLineToolEnvironmentVariableValue {
    var environmentVariableStringValue: String? { get }
}

extension CLT {
    public typealias EnvironmentVariableValue = _CommandLineToolEnvironmentVariableValue
}

extension Optional: CLT.EnvironmentVariableValue where Wrapped: CLT.EnvironmentVariableValue {
    public var environmentVariableStringValue: String? {
        self?.environmentVariableStringValue
    }
}

extension Bool: CLT.EnvironmentVariableValue {
    public var environmentVariableStringValue: String? {
        String(describing: self)
    }
}

extension Int: CLT.EnvironmentVariableValue {
    public var environmentVariableStringValue: String? {
        String(self)
    }
}

extension String: CLT.EnvironmentVariableValue {
    public var environmentVariableStringValue: String? {
        self
    }
}

extension URL: CLT.EnvironmentVariableValue {
    public var environmentVariableStringValue: String? {
        path
    }
}
