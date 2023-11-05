//
// Copyright (c) Vatsal Manot
//

import Swallow

public enum DependencyAttribute {
    case unstashable
}

public protocol DependencyKey<Value>: HeterogeneousDictionaryKey<Dependencies, Self.Value> {
    static var attributes: Set<DependencyAttribute> { get }
    
    static var defaultValue: Value { get }
}
