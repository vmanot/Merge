//
// Copyright (c) Vatsal Manot
//

import Swallow

@_spi(Internal)
public enum DependencyAttribute {
    case unstashable
}

public protocol DependencyKey<Value>: HeterogeneousDictionaryKey<Dependencies, Self.Value> {
    @_spi(Internal)
    static var attributes: Set<DependencyAttribute> { get }
    
    static var defaultValue: Value { get }
}


@_spi(Internal)
public protocol _DependencyPropertyWrapperScope {
    
}

extension DependencyKey {
    @_spi(Internal)
    public static var attributes: Set<DependencyAttribute> {
        []
    }
}
