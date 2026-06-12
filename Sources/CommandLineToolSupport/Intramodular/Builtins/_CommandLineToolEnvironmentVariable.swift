//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

extension CLT {
    public typealias EnvironmentVariable<Value: EnvironmentVariableValue> = _CommandLineToolEnvironmentVariable<Value>
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineTool {
    public typealias EnvironmentVariable<T: CLT.EnvironmentVariableValue> = _CommandLineToolEnvironmentVariable<T>
}

public protocol _CommandLineToolEnvironmentVariableProtocol: PropertyWrapper where WrappedValue: CLT.EnvironmentVariableValue {
    /// The name of the environment variable as it will be passed in the actual command being invoked.
    ///
    /// For e.g. `TARGET_BUILD_DIR` for `xcodebuild`.
    var name: String { get }
}

@propertyWrapper
public struct _CommandLineToolEnvironmentVariable<WrappedValue: CLT.EnvironmentVariableValue>: _CommandLineToolEnvironmentVariableProtocol {
    var _wrappedValue: WrappedValue
    
    public let name: String
    public var defaultValue: WrappedValue {
        wrappedValue
    }
    
    public var wrappedValue: WrappedValue {
        get {
            _wrappedValue
        } set {
            _wrappedValue = newValue
        }
    }
    
    public init(wrappedValue: WrappedValue, name: String) {
        self._wrappedValue = wrappedValue
        self.name = name
    }
    
    public init(name: String, defaultValue: WrappedValue) {
        self.init(wrappedValue: defaultValue, name: name)
    }
    
    public init(name: String) where WrappedValue: ExpressibleByNilLiteral {
        self.init(wrappedValue: nil, name: name)
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineTool {
    public func setEnvironmentVariable<Variable: _CommandLineToolEnvironmentVariableProtocol>(
        _ keyPath: KeyPath<Self.EnvironmentVariables.Type, Variable>,
        _ value: Variable.WrappedValue
    ) {
        let variable = Self.EnvironmentVariables.self[keyPath: keyPath]
        
        self.environmentVariables[variable.name] = value
    }
}

// MARK: - Auxiliary

/// This type is used to satisfy the default for `CommandLineTool.EnvironmentVariables`. 
public struct _CommandLineTool_DefaultEnvironmentVariables {
    
}

