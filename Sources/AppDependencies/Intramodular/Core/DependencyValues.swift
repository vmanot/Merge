//
// Copyright (c) Vatsal Manot
//

import Swallow

public typealias DependencyValues = HeterogeneousDictionary<Dependencies>

extension DependencyValues {
    public subscript<Key: DependencyKey>(
        key: Key.Type
    ) -> Key.Value {
        get {
            self[key] ?? key.defaultValue
        } set {
            self[key as any HeterogeneousDictionaryKey<Dependencies, Key.Value>.Type] = newValue
        }
    }
}
