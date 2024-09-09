//
// Copyright (c) Vatsal Manot
//

import Diagnostics
private import Runtime
@_spi(Internal) import Swallow
import SwiftUI

/// A marker protocol to be implemented via a macro @LogicalParent(Parent.self)
public protocol _LogicalParentConsuming<LogicalParentType> {
    associatedtype LogicalParentType
}

extension _LogicalParentConsuming {
    public var _opaque_LogicalParentType: Any.Type {
        LogicalParentType.self
    }
}

/// A logical parent provided via by dependency-injection.
@propertyWrapper
public final class LogicalParent<Parent>: Codable, _TaskDependenciesConsuming {
    private let lock = OSUnfairLock()
    
    @ReferenceBox
    var _resolvedValue = Weak<Parent>(nil)
    var _hasConsumedDependencies: Bool = false
    
    @TaskDependency(
        \._logicalParent,
         _resolve: {
             try $0.map({ try cast($0.wrappedValue) })
         }
    )
    var parent: Parent?
    
    package fileprivate(set) var _wrappedValue: Parent? {
        get {
            parent ?? _resolvedValue.wrappedValue
        } set {
            _resolvedValue.wrappedValue = newValue
        }
    }
    
    public var wrappedValue: Parent {
        _wrappedValue!
    }
    
    public var projectedValue: LogicalParent {
        self
    }
    
    public init() {
        
    }
    
    public init(_wrappedValue wrappedValue: Parent) {
        self.parent = wrappedValue
    }
    
    public func __consume(
        _ dependencies: TaskDependencies
    ) throws {
        lock.acquireOrBlock()
        
        defer {
            lock.relinquish()
        }
        
        guard _wrappedValue == nil, !_hasConsumedDependencies else {
            return
        }
        
        _ = try? $parent.__consume(dependencies)
        
        _resolvedValue = Weak(dependencies[\._logicalParent]?.wrappedValue as? Parent)
        
        if _wrappedValue != nil {
            _hasConsumedDependencies = true
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        
    }
    
    public convenience init(from decoder: Decoder) throws {
        self.init()
    }
}

extension LogicalParent: Hashable {
    private var _hashableView: _HashableExistential<any Hashable> {
        get throws {
            let parent = try $parent.get()
            
            if !(parent is (any Hashable)), swift_isClassType(type(of: parent)) {
                return try _HashableExistential(erasing: ObjectIdentifier(parent as AnyObject))
            } else {
                return try _HashableExistential(erasing: $parent.get())
            }
        }
    }
    
    public static func == (lhs: LogicalParent, rhs: LogicalParent) -> Bool {
        do {
            return try lhs._hashableView == rhs._hashableView
        } catch {
            return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        #try(.optimistic) {
            try hasher.combine(_hashableView)
        }
    }
}

extension Binding {
    public func _withLogicalParent<Parent>(
        _ parent: Parent
    ) -> Binding<Value> {
        Binding<Value>(
            get: {
                SwiftDI._withLogicalParent(parent) {
                    self.wrappedValue
                }
            },
            set: { (newValue: Value) in
                SwiftDI._withLogicalParent(parent) {
                    self.wrappedValue = newValue
                }
            }
        )
    }
    
    public func _assigningLogicalParent<Parent>(
        _ parent: Parent,
        to keyPath: KeyPath<Value, LogicalParent<Parent>>
    ) -> Binding<Value> {
        let parent = parent
        
        return withExtendedLifetime(parent) {
            Binding<Value>(
                get: {
                    let result: Value = self.wrappedValue
                    
                    if result[keyPath: keyPath]._wrappedValue == nil {
                        result[keyPath: keyPath]._wrappedValue = parent
                    }
                    
                    return result
                },
                set: { (newValue: Value) in
                    if newValue[keyPath: keyPath]._wrappedValue == nil {
                        newValue[keyPath: keyPath]._wrappedValue = parent
                    }
                    
                    self.wrappedValue = newValue
                }
            )
        }
    }
}

public func _withLogicalParent<Parent, Result>(
    _ parent: Parent?,
    operation: () throws -> Result
) rethrows -> Result {
    return try withTaskDependencies(from: parent) {
        try withTaskDependencies { (dependencies: inout TaskDependencies) -> Void in
            #try(.optimistic) {
                try dependencies._setLogicalParent(parent)
            }
        } operation: { () -> Result in
            if parent != nil {
                assert(TaskDependencies.current[\._logicalParent] != nil)
            }
            
            let result: Result = try operation()
            
            if parent != nil {
                if let mirror = InstanceMirror(result) {
                    mirror._smartForEachField(ofPropertyWrapperType: (any _TaskDependenciesConsuming).self) { element in
                        #try(.optimistic) {
                            try element.__consume(TaskDependencies.current)
                        }
                    }
                }
            }
            
            return result
        }
    }
}

public func _withLogicalParent<Parent, Result>(
    _ parent: Parent?,
    operation: () async throws -> Result
) async throws -> Result {
    try await withTaskDependencies {
        try $0._setLogicalParent(parent)
    } operation: {
        try await withTaskDependencies(from: parent) {
            try await operation()
        }
    }
}

public func _withLogicalParent<Parent, Result>(
    _ parent: Parent,
    operation: (Parent) throws -> Result
) throws -> Result {
    try _withLogicalParent(Optional(parent)) {
        try operation(parent)
    }
}

public func _withLogicalParent<Parent, Result>(
    _ parent: Parent,
    operation: (Parent) async throws -> Result
) async throws -> Result {
    try await _withLogicalParent(Optional(parent)) {
        try await operation(parent)
    }
}

public func _withLogicalParent<Parent, Result>(
    ofType parentType: Parent.Type,
    operation: (Parent) throws -> Result
) throws -> Result {
    do {
        let parent = try cast(
            TaskDependencies.current[unwrapping: \._logicalParent].wrappedValue.unwrap(),
            to: parentType
        )
        
        return try operation(parent)
    } catch {
        runtimeIssue(error)
        
        throw error
    }
}

// MARK: - Auxiliary

extension TaskDependencyValues {
    @_spi(Internal)
    public struct LogicalParentKey: TaskDependencyKey {
        public typealias Value = Optional<Weak<Any>>
        
        public static let defaultValue: Value = nil
        
        public static var attributes: Set<_TaskDependencyAttribute> {
            [.unstashable]
        }
    }
    
    @_spi(Internal)
    public var _logicalParent: LogicalParentKey.Value {
        get {
            self[LogicalParentKey.self]
        } set {
            self[LogicalParentKey.self] = newValue
        }
    }
}

extension TaskDependencies {
    fileprivate mutating func _setLogicalParent<Parent>(
        _ parent: Parent?
    ) throws {
        if let parent {
            self[\TaskDependencyValues._logicalParent] = Weak(parent)
        } else {
            self[\TaskDependencyValues._logicalParent] = nil
        }
    }
}

// MARK: - Auxiliary

extension KeyedDecodingContainer {
    public func decode<T>(
        _ type: LogicalParent<T>.Type,
        forKey key: Key
    ) throws -> LogicalParent<T> {
        return .init()
    }
}
