//
// Copyright (c) Vatsal Manot
//

import Foundation

public protocol EnvironmentVariableCatalogEntry {
    associatedtype Value: EnvironmentVariableValue
    
    var name: String { get }
    var variableName: EnvironmentVariableName { get }
    var defaultValue: Value { get }
}

public struct EnvironmentVariable<Value: EnvironmentVariableValue>: EnvironmentVariableCatalogEntry, Sendable {
    public let variableName: EnvironmentVariableName
    public let defaultValue: Value
    
    public var name: String {
        variableName.rawValue
    }
    
    public init(
        _ variableName: EnvironmentVariableName,
        defaultValue: Value
    ) {
        self.variableName = variableName
        self.defaultValue = defaultValue
    }
    
    public init(
        name: String,
        defaultValue: Value
    ) {
        self.init(
            EnvironmentVariableName(name),
            defaultValue: defaultValue
        )
    }
}

extension EnvironmentVariable: Equatable where Value: Equatable {
    
}

extension EnvironmentVariable: Hashable where Value: Hashable {
    
}

extension EnvironmentVariable {
    public init(_ variableName: EnvironmentVariableName) where Value: ExpressibleByNilLiteral {
        self.init(variableName, defaultValue: nil)
    }
    
    public init(name: String) where Value: ExpressibleByNilLiteral {
        self.init(EnvironmentVariableName(name))
    }
    
    public func readRawValue(
        from environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> String? {
        environment[name]
    }
}
