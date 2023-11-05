//
// Copyright (c) Vatsal Manot
//

import Swallow

@_spi(Internal)
public struct TaskContextValues {
    public var base: HeterogeneousDictionary<TaskContextValues>
    
    fileprivate init() {
        self.base = .init()
    }
    
    public subscript<Key: TaskContextKey>(_ key: Key.Type) -> Key.Value {
        get {
            base[key] ?? key.defaultValue
        } set {
            base[key] = newValue
        }
    }
}

@_spi(Internal)
public protocol TaskContextKey<Value>: HeterogeneousDictionaryKey<TaskContextValues, Self.Value> {
    static var defaultValue: Value { get }
}

@_spi(Internal)
extension TaskContextValues {
    @TaskLocal static var current: TaskContextValues = .init()
}
