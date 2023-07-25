//
// Copyright (c) Vatsal Manot
//

import Swallow

@propertyWrapper
public struct LogicalParent<Value: AnyObject>: _DependenciesUsing {
    @Dependency(
        \._logicalParent,
         _resolve: { try ($0?.wrappedValue).flatMap({ try cast($0) }) }
    ) var parent: Value
    
    public var wrappedValue: Value {
        parent
    }
    
    public init() {
        
    }
    
    public func _useDependencies(_ dependencies: Dependencies) throws {
        try $parent._useDependencies(dependencies)
    }
}

public func _withLogicalParent<Parent, Result>(
    _ parent: Parent?,
    operation: () throws -> Result
) throws -> Result {
    try withDependencies {
        if let parent {
            $0[\._logicalParent] = Weak(try cast(parent, to: AnyObject.self))
        }
    } operation: {
        try withDependencies(from: parent) {
            try operation()
        }
    }
}

public func _withLogicalParent<Parent, Result>(
    _ parent: Parent,
    operation: (Parent) throws -> Result
) throws -> Result {
    try withDependencies(from: Optional(parent)) {
        try operation(parent)
    }
}

extension DependencyValues {
    struct LogicalParentKey: DependencyKey {
        typealias Value = Optional<Weak<AnyObject>>
        
        static let defaultValue: Value = nil
        
        static var attributes: Set<DependencyAttribute> {
            [.unstashable]
        }
    }
    
    var _logicalParent: LogicalParentKey.Value {
        get {
            self[LogicalParentKey.self]
        } set {
            self[LogicalParentKey.self] = newValue
        }
    }
}
