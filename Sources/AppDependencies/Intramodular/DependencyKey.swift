//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A hack so that `Domain` can be inferred to be `Dependencies`.
public protocol _DependencyKey {
    typealias Domain = Dependencies
}

/// A key for accessing dependencies in the local task context.
public protocol DependencyKey<Value>: _DependencyKey, HeterogeneousDictionaryKey<Dependencies, Self.Value> where Domain == Dependencies {
    @_spi(Internal)
    static var attributes: Set<_DependencyAttribute> { get }
    
    static var defaultValue: Value { get }
}

// MARK: - WIP

@_spi(Internal)
public protocol _DependencyPropertyWrapperScope {
    
}

public enum _DependencyAttribute {
    case unstashable
}

extension DependencyKey {
    public static var attributes: Set<_DependencyAttribute> {
        []
    }
}

// MARK: - Auxiliary

public struct _OptionalDependencyKey<T>: DependencyKey {
    public typealias Domain = Dependencies
    public typealias Value = T?
    
    public static var defaultValue: Value {
        nil
    }
}
