//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Swallow
import SwallowMacrosClient

@_transparent
@discardableResult
public func withTaskDependencies<Result>(
    _ updateValuesForOperation: (inout TaskDependencies) throws -> Void,
    operation: () throws -> Result
) rethrows -> Result {
    var dependencies = TaskDependencies._current
    
    try updateValuesForOperation(&dependencies)
    
    return try TaskDependencies.$_current.withValue(dependencies) {
        let result: Result = try operation()
        
        #try(.optimistic) {
            try dependencies._stashInOrProvideTo(result)
        }
        
        return result
    }
}

@discardableResult
public func withTaskDependencies<Result>(
    operation: () throws -> Result
) rethrows -> Result {
    try withTaskDependencies({ _ in }, operation: operation)
}

#if swift(>=6)
@_transparent
@discardableResult
public func withTaskDependencies<Result>(
    isolation: isolated (any Actor)? = #isolation,
    _ updateValuesForOperation: (inout TaskDependencies) async throws -> Void,
    operation: () async throws -> Result
) async rethrows -> Result {
    var dependencies = TaskDependencies._current
    
    try await updateValuesForOperation(&dependencies)
    
    return try await TaskDependencies.$_current.withValue(dependencies) {
        let result = try await operation()
        
        #try(.optimistic) {
            try dependencies._stashInOrProvideTo(result)
        }
        
        return result
    }
}
#else
@discardableResult
public func withTaskDependencies<Result>(
    _ updateValuesForOperation: (inout TaskDependencies) async throws -> Void,
    operation: () async throws -> Result
) async rethrows -> Result {
    var dependencies = TaskDependencies._current
    
    try await updateValuesForOperation(&dependencies)
    
    return try await TaskDependencies.$_current.withValue(dependencies) {
        let result = try await operation()
        
        #try(.optimistic) {
            try dependencies._stashInOrProvideTo(result)
        }
        
        return result
    }
}
#endif

#if swift(>=6)
@_transparent
@discardableResult
public func withTaskDependency<Dependency, Result>(
    isolation: isolated (any Actor)? = #isolation,
    _ dependencyKey: WritableKeyPath<TaskDependencyValues, Dependency>,
    _ dependency: Dependency,
    operation: () async throws -> Result
) async rethrows -> Result {
    try await withTaskDependencies {
        $0[dependencyKey] = dependency
    } operation: {
        try await operation()
    }
}

@_transparent
@discardableResult
public func withTaskDependencies<Result>(
    isolation: isolated (any Actor)? = #isolation,
    operation: () async throws -> Result
) async rethrows -> Result {
    try await withTaskDependencies({ _ in }, operation: operation)
}
#elseif canImport(Translation)
@_transparent
@discardableResult
public func withTaskDependency<Dependency, Result>(
    _ dependencyKey: WritableKeyPath<TaskDependencyValues, Dependency>,
    _ dependency: Dependency,
    operation: () async throws -> Result
) async rethrows -> Result {
    try await withTaskDependencies {
        $0[dependencyKey] = dependency
    } operation: {
        try await operation()
    }
}

@_transparent
@discardableResult
public func withTaskDependencies<Result>(
    operation: () async throws -> Result
) async rethrows -> Result {
    try await withTaskDependencies({ _ in }, operation: operation)
}
#else
@_transparent
@_unsafeInheritExecutor
@discardableResult
public func withDependency<Dependency, Result>(
    _ dependencyKey: WritableKeyPath<TaskDependencyValues, Dependency>,
    _ dependency: Dependency,
    operation: () async throws -> Result
) async rethrows -> Result {
    try await withTaskDependencies {
        $0[dependencyKey] = dependency
    } operation: {
        try await operation()
    }
}

@_transparent
@_unsafeInheritExecutor
@discardableResult
public func withTaskDependencies<Result>(
    operation: () async throws -> Result
) async rethrows -> Result {
    try await withTaskDependencies({ _ in }, operation: operation)
}
#endif

@_transparent
@discardableResult
public func withTaskDependency<Dependency, Result>(
    _ dependencyKey: WritableKeyPath<TaskDependencyValues, Dependency>,
    _ dependency: Dependency,
    operation: () throws -> Result
) rethrows -> Result {
    try withTaskDependencies {
        $0[dependencyKey] = dependency
    } operation: {
        try operation()
    }
}

@_transparent
@discardableResult
public func withTaskDependencies<Subject, Result>(
    from subject: Subject,
    _ updateValuesForOperation: (inout TaskDependencies) throws -> Void,
    operation: () throws -> Result
) rethrows -> Result {
    let dependencies = TaskDependencies(reflecting: subject)
    
    return try withTaskDependencies {
        $0 = dependencies.merging($0)
        
        try updateValuesForOperation(&$0)
    } operation: {
        let result: Result = try operation()
        
        return result
    }
}

@_transparent
@discardableResult
public func withTaskDependencies<Subject, Result>(
    from subject: Subject,
    _ updateValuesForOperation: (inout TaskDependencies) async throws -> Void,
    operation: () async throws -> Result
) async rethrows -> Result {
    let dependencies = TaskDependencies(reflecting: subject)
    
    return try await withTaskDependencies {
        $0 = dependencies.merging($0)
        
        try await updateValuesForOperation(&$0)
    } operation: {
        try await operation()
    }
}

@_transparent
@discardableResult
public func withTaskDependencies<Subject, Result>(
    from subject: Subject,
    operation: () throws -> Result
) rethrows -> Result {
    try withTaskDependencies(from: subject, { _ in }, operation: operation)
}

@_transparent
@discardableResult
public func withTaskDependencies<Subject, Result>(
    from subject: Subject,
    operation: () async throws -> Result
) async rethrows -> Result {
    try await withTaskDependencies(from: subject, { _ in }, operation: operation)
}
