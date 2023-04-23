//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

@discardableResult
public func withDependencies<Result>(
    _ updateValuesForOperation: (inout Dependencies) throws -> Void,
    operation: () throws -> Result
) rethrows -> Result {
    var dependencies = Dependencies.current
    
    try updateValuesForOperation(&dependencies)
    
    return try Dependencies.$current.withValue(dependencies) {
        let result = try operation()
        
        return result
    }
}

@_unsafeInheritExecutor
@discardableResult
public func withDependencies<Result>(
    _ updateValuesForOperation: (inout Dependencies) async throws -> Void,
    operation: () async throws -> Result
) async rethrows -> Result {
    var dependencies = Dependencies.current
    
    try await updateValuesForOperation(&dependencies)
    
    return try await Dependencies.$current.withValue(dependencies) {
        let result = try await operation()
        
        return result
    }
}

@discardableResult
public func withDependencies<Subject, Result>(
    from subject: Subject,
    _ updateValuesForOperation: (inout Dependencies) throws -> Void,
    operation: () throws -> Result
) rethrows -> Result {
    let dependencies = Dependencies(from: subject)
    
    return try withDependencies {
        $0 = Dependencies.merge(lhs: dependencies, rhs: $0)
        
        try updateValuesForOperation(&$0)
    } operation: {
        try operation()
    }
}

@discardableResult
public func withDependencies<Subject, Result>(
    from subject: Subject,
    _ updateValuesForOperation: (inout Dependencies) async throws -> Void,
    operation: () async throws -> Result
) async rethrows -> Result {
    let dependencies = Dependencies(from: subject)
    
    return try await withDependencies {
        $0 = Dependencies.merge(lhs: dependencies, rhs: $0)
        
        try await updateValuesForOperation(&$0)
    } operation: {
        try await operation()
    }
}

@discardableResult
public func withDependencies<Subject, Result>(
    from subject: Subject,
    operation: () throws -> Result
) rethrows -> Result {
    try withDependencies(from: subject, { _ in }, operation: operation)
}

@discardableResult
public func withDependencies<Subject, Result>(
    from subject: Subject,
    operation: () async throws -> Result
) async rethrows -> Result {
    try await withDependencies(from: subject, { _ in }, operation: operation)
}

extension Dependencies {
    fileprivate init<T>(from subject: T)  {
        let reflected = Mirror(reflecting: subject).children
            .lazy
            .compactMap({ $1 as? (any _DependencyPropertyWrapperType) })
            .first?
            .initialDependencies
        
        if let reflected {
            self = reflected
        } else {
            self.init()
        }
    }
}
