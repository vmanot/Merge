//
// Copyright (c) Vatsal Manot
//

import Combine
import ObjectiveC
import Swallow
import SwiftUI

@discardableResult
public func withDependencies<Result>(
    _ updateValuesForOperation: (inout Dependencies) throws -> Void,
    operation: () throws -> Result
) rethrows -> Result {
    var dependencies = Dependencies._current
    
    try updateValuesForOperation(&dependencies)
    
    return try Dependencies.$_current.withValue(dependencies) {
        let result = try operation()
        
        dependencies._stashInOrProvideTo(result)
        
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
        
        dependencies._stashInOrProvideTo(result)
        
        return result
    }
}

@_unsafeInheritExecutor
@discardableResult
public func withDependency<Dependency, Result>(
    _ dependencyKey: WritableKeyPath<DependencyValues, Dependency>,
    _ dependency: Dependency,
    operation: () async throws -> Result
) async rethrows -> Result {
    try await withDependencies {
        $0[dependencyKey] = dependency
    } operation: {
        try await operation()
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
public func withDependency<Dependency, Result>(
    _ dependencyKey: WritableKeyPath<DependencyValues, Dependency>,
    _ dependency: Dependency,
    operation: () throws -> Result
) rethrows -> Result {
    try withDependencies {
        $0[dependencyKey] = dependency
    } operation: {
        try operation()
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
        $0 = dependencies.merging($0)
        
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
        $0 = dependencies.merging($0)
        
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
        TODO.here(.optimize)
        
        self.init()
        
        if let reflected = Mirror(reflecting: subject).children
            .lazy
            .compactMap({ $1 as? (any _DependencyPropertyWrapperType) })
            .first?
            .initialDependencies {
            mergeInPlace(with: reflected)
        }
        
        if let stashed = _DependenciesStasher(from: subject)?.fetch() {
            mergeInPlace(with: stashed)
        }
        
        if let subject = subject as? _DependenciesProviding {
            mergeInPlace(with: subject._providedDependencies)
        }
    }
    
    func stashable() -> Dependencies {
        .init(
            unkeyedValues: unkeyedValues,
            unkeyedValueTypes: unkeyedValueTypes,
            keyedValues: .init(_unsafeUniqueKeysAndValues: keyedValues.filter {
                !($0.key as! any DependencyKey.Type).attributes.contains(.unstashable)
            })
        )
    }
    
    /// Stash the dependencies in the given subject if its an object.
    ///
    /// Provide the subject with dependencies if it conforms to `_DependenciesUsing`.
    func _stashInOrProvideTo<T>(_ subject: T) {
        let subject = _unwrapPossiblyTypeErasedValue(subject)
        
        if let stasher = _DependenciesStasher(from: subject) {
            stasher.stash(self.stashable())
        }
        
        do {
            do {
                try (subject as? _DependenciesUsing)?._useDependencies(self)
                
                try Mirror(reflecting: subject).children
                    .lazy
                    .compactMap({ $1 as? (any _DependenciesUsing) })
                    .forEach {
                        try $0._useDependencies(self)
                    }
            } catch {
                throw DependenciesError.failedToUseDependencies(error)
            }
        } catch {
            assertionFailure(error)
        }
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
    
    func fetch() -> Dependencies? {
        guard let value = objc_getAssociatedObject(
            subject,
            &Self.objc_dependenciesKey
        ) else {
            return nil
        }
        
        return (value as! Dependencies)
    }
    
    func stash(_ dependencies: Dependencies) {
        objc_setAssociatedObject(
            subject,
            &Self.objc_dependenciesKey,
            dependencies,
            .OBJC_ASSOCIATION_RETAIN
        )
    }
}

public protocol _DependenciesProviding {
    var _providedDependencies: Dependencies { get }
}

