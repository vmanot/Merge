//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import SwiftUI
import Swallow

public protocol _DependenciesUsing {
    func _useDependencies(_ dependencies: Dependencies) throws
}

protocol _DependencyPropertyWrapperType: PropertyWrapper {
    var initialDependencies: Dependencies { get }
}

@propertyWrapper
public struct Dependency<Value>: _DependenciesUsing, _DependencyPropertyWrapperType, DynamicProperty, Logging, @unchecked Sendable {
    public let logger = PassthroughLogger()
    
    @Environment(\._dependencies) var _SwiftUI_dependencies
    
    private var _isInSwiftUIView: Bool = false

    let initialDependencies: Dependencies
    let resolveValue: @Sendable (Dependencies) throws -> Value?
    var assignedValue: Value?
    let deferredAssignedValue = ReferenceBox<Value?>(nil)
    
    public var wrappedValue: Value {
        get {
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
    
    public func _useDependencies(_ dependencies: Dependencies) throws {
        if _isValueNil(assignedValue), try resolveValue(initialDependencies) == nil {
            let hadValue = !_isValueNil(deferredAssignedValue.wrappedValue)
            
            if let resolvedValue = try resolveValue(dependencies) {
                deferredAssignedValue.wrappedValue = resolvedValue
            }
            
            if hadValue && deferredAssignedValue.wrappedValue == nil {
                assertionFailure()
            }
        }
    }
    
    private func dependenciesAvailable() -> Dependencies {
        if _isInSwiftUIView {
            var dependencies = _SwiftUI_dependencies
            
            dependencies.mergeInPlace(with: self.initialDependencies)
            dependencies.mergeInPlace(with: Dependencies.current)
            
            return dependencies
        } else {
            var dependencies = self.initialDependencies
            
            dependencies.mergeInPlace(with: Dependencies.current)
            
            return dependencies
        }
    }
    
    public func _get() throws -> Value {
        do {
            if let assignedValue, !_isValueNil(assignedValue) {
                return assignedValue
            } else if let assignedValue = deferredAssignedValue.wrappedValue, !_isValueNil(assignedValue) {
                return assignedValue
            }
            
            return try resolveValue(dependenciesAvailable()).unwrap()
        } catch {
            throw runtimeIssue(DependenciesError.failedToResolveDependency(Value.self))
        }
    }
    
    init(
        initialDependencies: Dependencies,
        resolveValue: @escaping @Sendable (Dependencies) throws -> Value?
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
            resolveValue: { try $0.resolve(.unkeyed(Value.self)) }
        )
    }
    
    public init(
        _ keyPath: KeyPath<DependencyValues, Value>
    ) {
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
            resolveValue: { $0[keyPath] }
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
    
    public init<T>(
        _ keyPath: KeyPath<DependencyValues, T>,
        as type: Value.Type
    ) {
        self.init(
            initialDependencies: Dependencies.current,
            resolveValue: { try cast($0[keyPath], to: Value.self) }
        )
    }
    
    public init<T>(
        _ keyPath: KeyPath<DependencyValues, T>,
        _resolve resolve: @escaping (T) throws -> Value?
    ) {
        self.init(
            initialDependencies: Dependencies.current,
            resolveValue: { try resolve($0[keyPath]) }
        )
    }
    
    public mutating func update() {
        _isInSwiftUIView = true
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
    
}

#if DEBUG
extension Dependency where Value: OptionalProtocol {
    public func get(file: StaticString = #fileID, line: UInt = #line) throws -> Value.Wrapped {
        try _get()._wrapped.unwrap(file: file, line: line)
    }
}
#else
extension Dependency where Value: OptionalProtocol {
    public func get() throws -> Value.Wrapped {
        try _get()._wrapped.unwrap()
    }
}
#endif
