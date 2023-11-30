//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

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

extension Dependencies {
    @TaskLocal public static var _current = Dependencies()
}
