//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Swallow
import SwallowMacrosClient

@_transparent
@discardableResult
public func withDependencies<Result>(
    _ updateValuesForOperation: (inout Dependencies) throws -> Void,
    operation: () throws -> Result
) rethrows -> Result {
    var dependencies = Dependencies._current
    
    try updateValuesForOperation(&dependencies)
    
    return try Dependencies.$_current.withValue(dependencies) {
        let result = try operation()
        
        #try(.optimistic) {
            try dependencies._stashInOrProvideTo(result)
        }
        
        return result
    }
}

@discardableResult
public func withDependencies<Result>(
    operation: () throws -> Result
) rethrows -> Result {
    try withDependencies({ _ in }, operation: operation)
}

@_transparent
@_unsafeInheritExecutor
@discardableResult
public func withDependencies<Result>(
    _ updateValuesForOperation: (inout Dependencies) async throws -> Void,
    operation: () async throws -> Result
) async rethrows -> Result {
    var dependencies = Dependencies._current
    
    try await updateValuesForOperation(&dependencies)
    
    return try await Dependencies.$_current.withValue(dependencies) {
        let result = try await operation()
        
        #try(.optimistic) {
            try dependencies._stashInOrProvideTo(result)
        }
        
        return result
    }
}

@_transparent
@_unsafeInheritExecutor
@discardableResult
public func withDependency<Dependency, Result>(
    _ dependencyKey: WritableKeyPath<TaskDependencyValues, Dependency>,
    _ dependency: Dependency,
    operation: () async throws -> Result
) async rethrows -> Result {
    try await withDependencies {
        $0[dependencyKey] = dependency
    } operation: {
        try await operation()
    }
}

@_transparent
@_unsafeInheritExecutor
@discardableResult
public func withDependencies<Result>(
    operation: () async throws -> Result
) async rethrows -> Result {
    try await withDependencies({ _ in }, operation: operation)
}

@_transparent
@discardableResult
public func withDependency<Dependency, Result>(
    _ dependencyKey: WritableKeyPath<TaskDependencyValues, Dependency>,
    _ dependency: Dependency,
    operation: () throws -> Result
) rethrows -> Result {
    try withDependencies {
        $0[dependencyKey] = dependency
    } operation: {
        try operation()
    }
}

@_transparent
@discardableResult
public func withDependencies<Subject, Result>(
    from subject: Subject,
    _ updateValuesForOperation: (inout Dependencies) throws -> Void,
    operation: () throws -> Result
) rethrows -> Result {
    let dependencies = Dependencies(from: subject)
    
    return try withDependencies {
        $0 = dependencies.merging($0)
        
        try updateValuesForOperation(&$0)
    } operation: {
        try operation()
    }
}

@_transparent
@discardableResult
public func withDependencies<Subject, Result>(
    from subject: Subject,
    _ updateValuesForOperation: (inout Dependencies) async throws -> Void,
    operation: () async throws -> Result
) async rethrows -> Result {
    let dependencies = Dependencies(from: subject)
    
    return try await withDependencies {
        $0 = dependencies.merging($0)
        
        try await updateValuesForOperation(&$0)
    } operation: {
        try await operation()
    }
}

@_transparent
@discardableResult
public func withDependencies<Subject, Result>(
    from subject: Subject,
    operation: () throws -> Result
) rethrows -> Result {
    try withDependencies(from: subject, { _ in }, operation: operation)
}

@_transparent
@discardableResult
public func withDependencies<Subject, Result>(
    from subject: Subject,
    operation: () async throws -> Result
) async rethrows -> Result {
    try await withDependencies(from: subject, { _ in }, operation: operation)
}
