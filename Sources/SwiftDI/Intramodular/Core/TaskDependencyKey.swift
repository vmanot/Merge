//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A hack so that `Domain` can be inferred to be `Dependencies`.
public protocol _TaskDependencyKey {
    typealias Domain = Dependencies
}

/// A key for accessing dependencies in the local task context.
public protocol TaskDependencyKey<Value>: _TaskDependencyKey, HeterogeneousDictionaryKey<Dependencies, Self.Value> where Domain == Dependencies {
    @_spi(Internal)
    static var attributes: Set<_TaskDependencyAttribute> { get }
    
    static var defaultValue: Value { get }
}

// MARK: - Auxiliary

public struct _OptionalTaskDependencyKey<T>: TaskDependencyKey {
    public typealias Domain = Dependencies
    public typealias Value = T?
    
    public static var defaultValue: Value {
        nil
    }
}
