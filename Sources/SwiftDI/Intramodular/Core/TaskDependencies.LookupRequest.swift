//
// Copyright (c) Vatsal Manot
//

private  import ObjectiveC
import Diagnostics
import Swallow

extension TaskDependencies {
    protocol _opaque_LookupRequest {
        func _opaque_resolve(from dependencies: TaskDependencies) throws -> Any?
    }
    
    public enum LookupRequest<Value>: _opaque_LookupRequest {
        case unkeyed(Value.Type)
        case keyed(KeyPath<TaskDependencyValues, Value>)
        
        func _opaque_resolve(
            from dependencies: TaskDependencies
        ) throws -> Any? {
            try dependencies.resolve(self)
        }
    }
    
    func resolve<T>(
        _ request: LookupRequest<T>
    ) throws -> T? {
        switch request {
            case .unkeyed(let type):
                return try unkeyedValues.firstAndOnly(ofType: type)
            case .keyed(let key):
                return self[key]
        }
    }
}
