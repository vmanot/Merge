//
// Copyright (c) Vatsal Manot
//

import Swallow

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
