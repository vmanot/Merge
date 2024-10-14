//
// Copyright (c) Vatsal Manot
//

import Swallow
/// A hack so that `Domain` can be inferred to be `Dependencies`.
public protocol _TaskDependencyKey {
    typealias Domain = TaskDependencies
}

/// A key for accessing dependencies in the local task context.
public protocol TaskDependencyKey<Value>: _TaskDependencyKey, HeterogeneousDictionaryKey<TaskDependencies, Self.Value> where Domain == TaskDependencies {
    @_spi(Internal)
    static var attributes: Set<_TaskDependencyAttribute> { get }
    
    static var defaultValue: Value { get }
}


// MARK: - Implementation

extension TaskDependencyKey {
    public static var attributes: Set<_TaskDependencyAttribute> {
        []
    }
}

// MARK: - Auxiliary

public enum _TaskDependencyAttribute {
    case unstashable
}

// MARK: - Implemented Conformances

public struct _OptionalTaskDependencyKey<T>: TaskDependencyKey {
    public typealias Domain = TaskDependencies
    public typealias Value = T?
    
    public static var defaultValue: Value {
        nil
    }
}
