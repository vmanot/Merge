//
// Copyright (c) Vatsal Manot
//

import Combine
import ObjectiveC
import Swallow

@discardableResult
public func withDependencies<Result>(
    _ updateValuesForOperation: (inout Dependencies) throws -> Void,
    operation: () throws -> Result
) rethrows -> Result {
    var dependencies = Dependencies._current
    
    try updateValuesForOperation(&dependencies)
    
    return try Dependencies.$_current.withValue(dependencies) {
        let result = try operation()
        
        dependencies.stashIfPossible(in: result)
        
        return result
    }
}

@discardableResult
public func withDependencies<Result>(
    operation: () throws -> Result
) rethrows -> Result {
    try withDependencies({ _ in }, operation: operation)
}

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
        
        dependencies.stashIfPossible(in: result)
        
        return result
    }
}

@_unsafeInheritExecutor
@discardableResult
public func withDependencies<Result>(
    operation: () async throws -> Result
) async rethrows -> Result {
    try await withDependencies({ _ in }, operation: operation)
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
    fileprivate init<T>(from subject: T) {
        let reflectedDependencies = Mirror(reflecting: subject).children
            .lazy
            .compactMap({ $1 as? (any _DependencyPropertyWrapperType) })
            .first?
            .initialDependencies
        
        if let reflectedDependencies {
            self = reflectedDependencies
        } else if let dependencies = _DependenciesStasher(from: subject)?.dependencies {
            self = dependencies
        } else {
            // runtimeIssue("Failed to extract any dependencies from \(subject).")
            
            self.init()
        }
    }
    
    func stashIfPossible<T>(in subject: T) {
        guard let stasher = _DependenciesStasher(from: subject) else {
            return
        }
        
        stasher.dependencies = self
    }
}

fileprivate struct _DependenciesStasher {
    private static var objc_dependenciesKey: UInt8 = 0
    
    let subject: AnyObject
    
    init?(from subject: Any) {
        guard type(of: subject) is AnyObject.Type else {
            return nil
        }
        
        self.subject = try! cast(subject, to: AnyObject.self)
    }
    
    public var dependencies: Dependencies? {
        get {
            guard let value = objc_getAssociatedObject(
                subject,
                &Self.objc_dependenciesKey
            ) else {
                return nil
            }
            
            return (value as! Dependencies)
        } nonmutating set {
            objc_setAssociatedObject(
                subject,
                &Self.objc_dependenciesKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN
            )
        }
    }
}
