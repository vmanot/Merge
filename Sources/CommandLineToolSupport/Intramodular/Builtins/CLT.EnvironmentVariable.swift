//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

extension CLT {
    public protocol _EnvironmentVariableProtocol {
        associatedtype Value: EnvironmentVariableValue
        
        var name: String { get }
        var defaultValue: Value { get }
    }
    
    public struct EnvironmentVariable<Value: EnvironmentVariableValue>: _EnvironmentVariableProtocol {
        public let name: String
        public let defaultValue: Value
        
        public init(name: String, defaultValue: Value) {
            self.name = name
            self.defaultValue = defaultValue
        }
    }
}

extension CLT.EnvironmentVariable {
    public init(name: String) where Value: ExpressibleByNilLiteral {
        self.init(name: name, defaultValue: nil)
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineTool {
    public func setEnvironmentVariable<Variable: CLT._EnvironmentVariableProtocol>(
        _ keyPath: KeyPath<Self.EnvironmentVariables.Type, Variable>,
        _ value: Variable.Value
    ) {
        let variable = Self.EnvironmentVariables.self[keyPath: keyPath]
        
        self.environmentVariables[variable.name] = value
    }
}
