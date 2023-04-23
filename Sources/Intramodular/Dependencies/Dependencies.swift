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
    case keyed(any DependencyKey<Value>)
    
    func _opaque_resolve(from dependencies: Dependencies) throws -> Any? {
        try dependencies.resolve(self)
    }
}

public struct Dependencies: @unchecked Sendable {
    var unkeyedValues: _BagOfExistentials<any Sendable>
    var unkeyedValueTypes: Set<Metatype<Any.Type>> = []
    
    var isEmpty: Bool {
        unkeyedValues.isEmpty
    }
    
    internal init(
        unkeyedValues: _BagOfExistentials<Sendable>,
        unkeyedValueTypes: Set<Metatype<Any.Type>>
    ) {
        self.unkeyedValues = unkeyedValues
        self.unkeyedValueTypes = unkeyedValueTypes
    }
    
    public init() {
        self.init(unkeyedValues: [], unkeyedValueTypes: [])
    }
    
    func resolve<T>(_ request: DependencyResolutionRequest<T>) throws -> T? {
        switch request {
            case .unkeyed(let type):
                return try unkeyedValues.firstAndOnly(ofType: type)
            case .keyed(_):
                fatalError()
        }
    }
    
    func merging(with other: Self) -> Self {
        Self.merge(lhs: self, rhs: other)
    }
    
    static func merge(lhs: Self, rhs: Self) -> Self {
        var rhsUnkeyedValues = rhs.unkeyedValues
        
        rhsUnkeyedValues.removeAll(where: { element -> Bool in
            lhs.unkeyedValueTypes.contains(where: {
                _isValueOfGivenType(element, type: $0.value)
            })
        })
        
        return Self(
            unkeyedValues: lhs.unkeyedValues.merge(with: rhsUnkeyedValues),
            unkeyedValueTypes: lhs.unkeyedValueTypes.union(rhs.unkeyedValueTypes)
        )
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
}

// MARK: - Auxiliary

public protocol DependencyKey<Value> {
    associatedtype Value
    
    static var defaultValue: Value { get }
}

extension Dependencies {
    @TaskLocal internal static var current = Dependencies()
}
