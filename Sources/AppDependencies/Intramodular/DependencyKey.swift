//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol DependencyKey<Value>: HeterogeneousDictionaryKey<Dependencies, Self.Value> {
    @_spi(Internal)
    static var attributes: Set<_DependencyAttribute> { get }
    
    static var defaultValue: Value { get }
}


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
