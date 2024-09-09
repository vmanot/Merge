//
// Copyright (c) Vatsal Manot
//

import Swallow

extension TaskDependency {
    public init() {
        self.init(
            initialTaskDependencies: TaskDependencies.current,
            resolveValue: { try $0.resolve(.unkeyed(Value.self)) }
        )
    }
    
    public init<T>() where Value == Optional<T> {
        self.init(
            initialTaskDependencies: TaskDependencies.current,
            resolveValue: { try $0.resolve(.unkeyed(T.self)) }
        )
    }
    
    public init(
        _ keyPath: KeyPath<TaskDependencyValues, Value>
    ) {
        self.init(
            initialTaskDependencies: TaskDependencies.current,
            resolveValue: { $0[keyPath] }
        )
    }
    
    @_disfavoredOverload
    public init(
        _ keyPath: KeyPath<TaskDependencyValues, Optional<Value>>
    ) {
        self.init(
            initialTaskDependencies: TaskDependencies.current,
            resolveValue: { $0[keyPath] }
        )
    }
        
    public init<T>(
        _ keyPath: KeyPath<TaskDependencyValues, Optional<T>>
    ) where Value == Optional<T> {
        self.init(
            initialTaskDependencies: TaskDependencies.current,
            resolveValue: { $0[keyPath] }
        )
    }
        
    public init<T>(
        _ keyPath: KeyPath<TaskDependencyValues, T>,
        _resolve resolve: @escaping (T) throws -> Optional<Value>
    ) {
        self.init(
            initialTaskDependencies: TaskDependencies.current,
            resolveValue: { try resolve($0[keyPath]) }
        )
    }
    
    public init<T>(
        _ keyPath: KeyPath<TaskDependencyValues, T>,
        as type: Value.Type
    ) {
        self.init(
            initialTaskDependencies: TaskDependencies.current,
            resolveValue: { try cast($0[keyPath], to: Value.self) }
        )
    }
}
