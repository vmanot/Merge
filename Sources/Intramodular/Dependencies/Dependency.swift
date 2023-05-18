//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Swallow

protocol _DependencyPropertyWrapperType: PropertyWrapper {
    var initialDependencies: Dependencies { get }
}

@propertyWrapper
public struct Dependency<Value>: _DependencyPropertyWrapperType, Logging, @unchecked Sendable {
    public let logger = PassthroughLogger()
        
    let initialDependencies: Dependencies
    let resolveValue: @Sendable (Dependencies) throws -> Value
    var assignedValue: Value?
    
    init(
        initialDependencies: Dependencies,
        resolveValue: @escaping @Sendable (Dependencies) throws -> Value
    ) {
        self.initialDependencies = initialDependencies
        self.resolveValue = resolveValue
    }
    
    public init<T>() where Value == Optional<T> {
        self.init(
            initialDependencies: Dependencies.current,
            resolveValue: { try $0.resolve(.unkeyed(T.self)) }
        )
    }
    
    public init() {
        self.init(
            initialDependencies: Dependencies.current,
            resolveValue: { try $0.resolve(.unkeyed(Value.self)).unwrap() }
        )
    }
    
    public init<T>(
        _ keyPath: KeyPath<DependencyValues, T>
    ) where Value == Optional<T> {
        self.init(
            initialDependencies: Dependencies.current,
            resolveValue: { $0[keyPath] }
        )
    }
    
    @_disfavoredOverload
    public init(
        _ keyPath: KeyPath<DependencyValues, Optional<Value>>
    ) {
        self.init(
            initialDependencies: Dependencies.current,
            resolveValue: { try $0[unwrapping: keyPath] }
        )
    }

    public init<T>(
        _ keyPath: KeyPath<DependencyValues, Optional<T>>
    ) where Value == Optional<T> {
        self.init(
            initialDependencies: Dependencies.current,
            resolveValue: { $0[keyPath] }
        )
    }
        
    public var wrappedValue: Value {
        get {
            if let assignedValue, !_isValueNil(assignedValue) {
                return assignedValue
            }
            
            do {
                return try get()
            } catch {
                assertionFailure(error)
                
                return try! _unsafeDummyValue(forType: Value.self)
            }
        } set {
            assignedValue = newValue
        }
    }
    
    public var projectedValue: Self {
        self
    }
    
    public func _get() throws -> Value {
        do {
            if let assignedValue, !_isValueNil(assignedValue) {
                return assignedValue
            }
            
            let dependencies = Dependencies._current.merging(with: self.initialDependencies)
            
            return try Dependencies.$_current.withValue(dependencies) {
                try resolveValue(dependencies)
            }
        } catch {
            logger.error(error)
            
            throw error
        }
    }
}

extension Dependency {
    public func get() throws -> Value {
        try _get()
    }
}

extension Dependency where Value: OptionalProtocol {
    @_disfavoredOverload
    @available(*, unavailable)
    public func get() throws -> Value {
        try _get()
    }
    
    public func get() throws -> Value.Wrapped {
        try _get()._wrapped.unwrap()
    }
}
