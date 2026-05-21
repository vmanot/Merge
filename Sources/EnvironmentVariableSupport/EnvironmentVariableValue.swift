//
// Copyright (c) Vatsal Manot
//

import Foundation

public protocol EnvironmentVariableValue: Sendable {
    var environmentVariableStringValue: String? { get }
}

extension Optional: EnvironmentVariableValue where Wrapped: EnvironmentVariableValue {
    public var environmentVariableStringValue: String? {
        self?.environmentVariableStringValue
    }
}

extension Bool: EnvironmentVariableValue {
    public var environmentVariableStringValue: String? {
        String(describing: self)
    }
}

extension Int: EnvironmentVariableValue {
    public var environmentVariableStringValue: String? {
        String(self)
    }
}

extension String: EnvironmentVariableValue {
    public var environmentVariableStringValue: String? {
        self
    }
}

extension URL: EnvironmentVariableValue {
    public var environmentVariableStringValue: String? {
        path
    }
}

