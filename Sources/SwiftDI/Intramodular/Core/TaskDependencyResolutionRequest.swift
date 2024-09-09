//
// Copyright (c) Vatsal Manot
//

private  import ObjectiveC
import Diagnostics
import Swallow

protocol _opaque_TaskDependencyResolutionRequest {
    func _opaque_resolve(from dependencies: TaskDependencies) throws -> Any?
}

public enum TaskDependencyResolutionRequest<Value>: _opaque_TaskDependencyResolutionRequest {
    case unkeyed(Value.Type)
    case keyed(KeyPath<TaskDependencyValues, Value>)
    
    func _opaque_resolve(from dependencies: TaskDependencies) throws -> Any? {
        try dependencies.resolve(self)
    }
}
