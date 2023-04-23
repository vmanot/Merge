//
// Copyright (c) Vatsal Manot
//

import Swallow

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

public protocol TaskContextKey: HeterogeneousDictionaryKey<TaskContextValues> {
    static var defaultValue: Value { get }
}

extension TaskContextValues {
    @TaskLocal static var current: TaskContextValues = .init()
}
