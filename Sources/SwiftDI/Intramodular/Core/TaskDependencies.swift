//
// Copyright (c) Vatsal Manot
//

private import Combine
import Swallow

@available(*, deprecated, renamed: "TaskDependencies")
public typealias Dependencies = TaskDependencies
@available(*, deprecated, renamed: "TaskDependency")
public typealias Dependency<Value> = TaskDependency<Value>
@available(*, deprecated, renamed: "TaskDependencyKey")
public typealias DependencyKey = TaskDependencyKey

public protocol _TaskDependenciesConsuming {
    func __consume(_: TaskDependencies) throws
}

public struct TaskDependencies: @unchecked Sendable {
    var unkeyedValues: _BagOfExistentials<any Sendable>
    var unkeyedValueTypes: Set<Metatype<Any.Type>> = []
    var keyedValues = HeterogeneousDictionary<TaskDependencies>()
    
    var isEmpty: Bool {
        unkeyedValues.isEmpty && keyedValues.isEmpty
    }
    
    internal init(
        unkeyedValues: _BagOfExistentials<Sendable>,
        unkeyedValueTypes: Set<Metatype<Any.Type>>,
        keyedValues: HeterogeneousDictionary<TaskDependencies>
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
        keyPath: KeyPath<TaskDependencyValues, T>
    ) -> T {
        get {
            keyedValues[keyPath: keyPath]
        }
    }
    
    public subscript<T>(
        unwrapping keyPath: KeyPath<TaskDependencyValues, Optional<T>>
    ) -> T {
        get throws {
            do {
                return try keyedValues[keyPath: keyPath].unwrap()
            } catch {
                throw TaskDependenciesError.init(
                    rawValue: .noValueForKey(keyPath),
                    location: .unavailable
                )
            }
        }
    }
    
    public subscript<T>(keyPath: WritableKeyPath<TaskDependencyValues, T>) -> T {
        get {
            keyedValues[keyPath: keyPath]
        } set {
            keyedValues[keyPath: keyPath] = newValue
        }
    }
}

extension TaskDependencies: MergeOperatable {
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
            keyedValues: lhs.keyedValues.merging(rhs.keyedValues, uniquingKeysWith: { lhs, rhs -> Any in
                guard !_isValueNil(rhs) else {
                    return lhs
                }
                
                return rhs
            })
        )
        
        assert(!result.isEmpty)
        
        return result
    }
}

extension TaskDependencies {
    public static var current: TaskDependencies {
        TaskDependencies._current
    }
    
    static func resolve<T>(
        _ dependency: TaskDependency<T>
    ) throws -> T {
        try dependency.get()
    }
    
    public static func resolve<T>(
        _ keyPath: KeyPath<TaskDependencyValues, Optional<T>>
    ) throws -> T {
        try Self.current[unwrapping: keyPath]
    }
}

// MARK: - Auxiliary

extension TaskDependencies {
    @TaskLocal public static var _current = TaskDependencies()
}

public struct TaskDependenciesError: CustomStringConvertible, Error, Hashable {
    public enum RawValue: Hashable {
        case noValueForKey(AnyKeyPath)
    }
    
    public let rawValue: RawValue
    public let location: SourceCodeLocation
    
    public var description: String {
        String(describing: rawValue)
    }
    
    public init(rawValue: RawValue, location: SourceCodeLocation) {
        self.rawValue = rawValue
        self.location = location
    }
}
