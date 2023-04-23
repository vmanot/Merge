//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

protocol _DependencyPropertyWrapperType: PropertyWrapper {
    var initialDependencies: Dependencies { get }
}

@propertyWrapper
public struct Dependency<Value>: _DependencyPropertyWrapperType, @unchecked Sendable {
    private let resolveValue: @Sendable (Dependencies) throws -> Value
    
    let initialDependencies: Dependencies
    
    public init<T>() where Value == Optional<T> {
        self.resolveValue = { try $0.resolve(.unkeyed(T.self)) }
        self.initialDependencies = Dependencies.current
    }
    
    public init() {
        self.resolveValue = { try $0.resolve(.unkeyed(Value.self)).unwrap() }
        self.initialDependencies = Dependencies.current
    }
        
    public var wrappedValue: Value {
        do {
            return try get()
        } catch {
            assertionFailure(error)
            
            return try! _unsafeDummyValue(forType: Value.self)
        }
    }
    
    public var projectedValue: Self {
        self
    }
    
    public func get() throws -> Value {
        let dependencies = Dependencies.current.merging(with: self.initialDependencies)
        
        return try Dependencies.$current.withValue(dependencies) {
            try resolveValue(dependencies)
        }
    }
}
