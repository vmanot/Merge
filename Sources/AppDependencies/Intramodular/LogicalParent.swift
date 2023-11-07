//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Swallow

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
public struct LogicalParent<Parent>: _DependenciesConsuming {
    @Dependency(
        \._logicalParent,
         _resolve: { try cast($0.unwrap().wrappedValue)  }
    )
    var parent: Parent
    
    public var wrappedValue: Parent {
        parent
    }
    
    public init() {
        
    }
    
    public func _consumeDependencies(_ dependencies: Dependencies) throws {
        try $parent._consumeDependencies(dependencies)
    }
}

extension LogicalParent: Codable {
    public func encode(to encoder: Encoder) throws {
        
    }
    
    public init(from decoder: Decoder) throws {
        self.init()
    }
}

extension LogicalParent: Hashable {
    private var _hashableView: _HashableExistential<any Hashable> {
        try! _HashableExistential(erasing: $parent.get())
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._hashableView == rhs._hashableView
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_hashableView)
    }
}

public func _withLogicalParent<Parent, Result>(
    _ parent: Parent?,
    operation: () throws -> Result
) throws -> Result {
    try withDependencies {
        try $0._setLogicalParent(parent)
    } operation: {
        try withDependencies(from: parent) {
            try operation()
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

extension DependencyValues {
    fileprivate struct LogicalParentKey: DependencyKey {
        typealias Value = Optional<Weak<Any>>
        
        static let defaultValue: Value = nil
        
        static var attributes: Set<DependencyAttribute> {
            [.unstashable]
        }
    }
    
    fileprivate var _logicalParent: LogicalParentKey.Value {
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
            self[\DependencyValues._logicalParent] = Weak(parent)
        } else {
            self[\DependencyValues._logicalParent] = Weak(nil)
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
