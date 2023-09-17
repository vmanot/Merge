//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

protocol _opaque_DependencyResolutionRequest {
    func _opaque_resolve(from dependencies: Dependencies) throws -> Any?
}

public enum DependencyResolutionRequest<Value>: _opaque_DependencyResolutionRequest {
    case unkeyed(Value.Type)
    case keyed(KeyPath<DependencyValues, Value>)
    
    func _opaque_resolve(from dependencies: Dependencies) throws -> Any? {
        try dependencies.resolve(self)
    }
}

public enum DependenciesError: Error {
    case failedToResolveDependency(Any.Type)
    case failedToUseDependencies(Error)
}

public struct Dependencies: @unchecked Sendable {
    var unkeyedValues: _BagOfExistentials<any Sendable>
    var unkeyedValueTypes: Set<Metatype<Any.Type>> = []
    var keyedValues = HeterogeneousDictionary<Dependencies>()
    
    var isEmpty: Bool {
        unkeyedValues.isEmpty && keyedValues.isEmpty
    }
    
    internal init(
        unkeyedValues: _BagOfExistentials<Sendable>,
        unkeyedValueTypes: Set<Metatype<Any.Type>>,
        keyedValues: HeterogeneousDictionary<Dependencies>
    ) {
        self.unkeyedValues = unkeyedValues
        self.unkeyedValueTypes = unkeyedValueTypes
        self.keyedValues = keyedValues
    }
    
    public init() {
        self.init(
            unkeyedValues: [],
            unkeyedValueTypes: [],
            keyedValues: .init()
        )
    }
    
    func resolve<T>(_ request: DependencyResolutionRequest<T>) throws -> T? {
        switch request {
            case .unkeyed(let type):
                return try unkeyedValues.firstAndOnly(ofType: type)
            case .keyed(let key):
                return self[key]
        }
    }
    
    public subscript<T>(unkeyed type: T.Type) -> T? {
        get {
            unkeyedValues.first(ofType: type)
        } set {
            if let newValue {
                unkeyedValues.replaceAll(ofType: type, with: newValue)
                
                unkeyedValueTypes.insert(.init(type))
            } else {
                unkeyedValues.removeAll(ofType: type)
                
                unkeyedValueTypes.remove(.init(type))
            }
        }
    }
    
    public subscript<T>(
        keyPath: KeyPath<DependencyValues, T>
    ) -> T {
        get {
            keyedValues[keyPath: keyPath]
        }
    }
    
    public subscript<T>(
        unwrapping keyPath: KeyPath<DependencyValues, Optional<T>>
    ) -> T {
        get throws {
            do {
                return try keyedValues[keyPath: keyPath].unwrap()
            } catch {
                throw _PlaceholderError()
            }
        }
    }
    
    public subscript<T>(keyPath: WritableKeyPath<DependencyValues, T>) -> T {
        get {
            keyedValues[keyPath: keyPath]
        } set {
            keyedValues[keyPath: keyPath] = newValue
        }
    }
}

extension Dependencies: MergeOperatable {
    public mutating func mergeInPlace(with other: Self) {
        self = Self.merge(lhs: self, rhs: other)
    }
    
    private static func merge(
        lhs: Self,
        rhs: Self
    ) -> Self {
        if lhs.isEmpty && rhs.isEmpty {
            return lhs
        }
        
        var lhsUnkeyedValues = lhs.unkeyedValues
        
        if !lhs.unkeyedValues.isEmpty && !rhs.unkeyedValues.isEmpty {
            lhsUnkeyedValues.removeAll(where: { element -> Bool in
                rhs.unkeyedValueTypes.contains(where: {
                    _isValueOfGivenType(element, type: $0.value)
                })
            })
        }
        
        let result = Self(
            unkeyedValues: rhs.unkeyedValues.merge(with: lhsUnkeyedValues),
            unkeyedValueTypes: lhs.unkeyedValueTypes.union(rhs.unkeyedValueTypes),
            keyedValues: lhs.keyedValues.merging(rhs.keyedValues, uniquingKeysWith: { lhs, rhs in rhs })
        )
        
        assert(!result.isEmpty)
        
        return result
    }
}

extension Dependencies {
    public static var current: Dependencies {
        Dependencies._current
    }
    
    static func resolve<T>(
        _ dependency: Dependency<T>
    ) throws -> T {
        try dependency.get()
    }
    
    public static func resolve<T>(
        _ keyPath: KeyPath<DependencyValues, Optional<T>>
    ) throws -> T {
        try Self.current[unwrapping: keyPath]
    }
}

// MARK: - Auxiliary

public enum DependencyAttribute {
    case unstashable
}

public protocol DependencyKey<Value>: HeterogeneousDictionaryKey<Dependencies, Self.Value> {
    static var attributes: Set<DependencyAttribute> { get }
    
    static var defaultValue: Value { get }
}

extension DependencyKey {
    public static var attributes: Set<DependencyAttribute> {
        []
    }
}

public struct _OptionalDependencyKey<T>: DependencyKey {
    public typealias Domain = Dependencies
    public typealias Value = T?
    
    public static var defaultValue: Value {
        nil
    }
}

public typealias DependencyValues = HeterogeneousDictionary<Dependencies>

extension DependencyValues {
    public subscript<Key: DependencyKey>(key: Key.Type) -> Key.Value {
        get {
            self[key] ?? key.defaultValue
        } set {
            self[key as any HeterogeneousDictionaryKey<Dependencies, Key.Value>.Type] = newValue
        }
    }
}

extension Dependencies {
    @TaskLocal public static var _current = Dependencies()
}
