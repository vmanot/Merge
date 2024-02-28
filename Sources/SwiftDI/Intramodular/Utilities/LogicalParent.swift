//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Swallow
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
    let _resolvedValue = ReferenceBox<Weak<Parent>>(.init(nil))
    var _hasConsumedDependencies: Bool = false
    
    @Dependency(
        \._logicalParent,
         _resolve: {
             try $0.map({ try cast($0.wrappedValue) })
         }
    )
    var parent: Parent?
    
    private var _wrappedValue: Parent? {
        parent ?? _resolvedValue.wrappedValue.wrappedValue
    }
    
    public var wrappedValue: Parent {
        _wrappedValue!
    }
    
    public init() {
        
    }
    
    public init(_wrappedValue wrappedValue: Parent) {
        self.parent = wrappedValue
    }
    
    public func __consume(
        _ dependencies: Dependencies
    ) throws {
        _ = try? $parent.__consume(dependencies)
        
        _resolvedValue.wrappedValue = Weak(dependencies[\._logicalParent]?.wrappedValue as? Parent)
        
        _hasConsumedDependencies = true
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
        try! lhs._hashableView == rhs._hashableView
    }
    
    public func hash(into hasher: inout Hasher) {
        try! hasher.combine(_hashableView)
    }
}

extension Binding {
    public func _withLogicalParent<Parent>(_ parent: Parent) -> Binding {
        Binding(
            get: {
                try! SwiftDI._withLogicalParent(parent) {
                    self.wrappedValue
                }
            },
            set: { newValue in
                try! SwiftDI._withLogicalParent(parent) {
                    self.wrappedValue = newValue
                }
            }
        )
    }
}

public func _withLogicalParent<Parent, Result>(
    _ parent: Parent?,
    operation: () throws -> Result
) throws -> Result {
    return try withDependencies(from: parent) {
        try withDependencies {
            try $0._setLogicalParent(parent)
        } operation: {
            if parent != nil {
                assert(Dependencies.current[\._logicalParent] != nil)
            }
            
            return try operation()
        }
    }
}

public func _withLogicalParent<Parent, Result>(
    _ parent: Parent?,
    operation: () async throws -> Result
) async throws -> Result {
    try await withDependencies {
        try $0._setLogicalParent(parent)
    } operation: {
        try await withDependencies(from: parent) {
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
            Dependencies.current[unwrapping: \._logicalParent].wrappedValue.unwrap(),
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

extension Dependencies {
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
