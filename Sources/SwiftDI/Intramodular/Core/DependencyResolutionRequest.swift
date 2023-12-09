//
// Copyright (c) Vatsal Manot
//

import ObjectiveC
import Diagnostics
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
