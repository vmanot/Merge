//
// Copyright (c) Vatsal Manot
//

import Swallow

public typealias TaskDependencyValues = HeterogeneousDictionary<TaskDependencies>

extension TaskDependencyValues {
    public subscript<Key: TaskDependencyKey>(
        key: Key.Type
    ) -> Key.Value {
        get {
            self[key] ?? key.defaultValue
        } set {
            self[key as any HeterogeneousDictionaryKey<TaskDependencies, Key.Value>.Type] = newValue
        }
    }
}
