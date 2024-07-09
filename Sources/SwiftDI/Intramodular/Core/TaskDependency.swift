//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import SwiftUI
import Swallow

protocol _TaskDependencyPropertyWrapperType: PropertyWrapper {
    var initialTaskDependencies: TaskDependencies { get }
}

/// A property wrapper that reads a dependency from a task's execution context.
///
/// This is similar to `@Environment` in SwiftUI.
@propertyWrapper
public struct TaskDependency<Value>: _TaskDependenciesConsuming, _TaskDependencyPropertyWrapperType, DynamicProperty, Logging, @unchecked Sendable {
    public let logger = PassthroughLogger()
    
    @Environment(\._dependencies) var _SwiftUI_dependencies
    
    private var _isInSwiftUIView: Bool = false
    
    let initialTaskDependencies: Dependencies
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
    
    public func __consume(_ dependencies: Dependencies) throws {
        if _isValueNil(assignedValue), try resolveValue(initialTaskDependencies) == nil {
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
            
            dependencies.mergeInPlace(with: self.initialTaskDependencies)
            dependencies.mergeInPlace(with: Dependencies.current)
            
            return dependencies
        } else {
            var dependencies = self.initialTaskDependencies
            
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
            if let type = Value.self as? ExpressibleByNilLiteral.Type {
                return type.init(nilLiteral: ()) as! Value
            }
            
            throw runtimeIssue(_SwiftDI.Error.failedToResolveDependency(Value.self))
        }
    }
    
    init(
        initialTaskDependencies: Dependencies,
        resolveValue: @escaping @Sendable (Dependencies) throws -> Value?
    ) {
        self.initialTaskDependencies = initialTaskDependencies
        self.resolveValue = resolveValue
    }
    
    public mutating func update() {
        _isInSwiftUIView = true
    }
}

extension TaskDependency {
    @_disfavoredOverload
    public func get() throws -> Value {
        try _get()
    }
    
    public func get() throws -> Value.Wrapped where Value: OptionalProtocol {
        try _get()._wrapped.unwrap()
    }
}
