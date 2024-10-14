//
// Copyright (c) Vatsal Manot
//

import Diagnostics
private import ObjectiveC
import Swallow

extension TaskDependencies {
    @usableFromInline
    init<T>(reflecting subject: T) {
        TODO.here(.optimize)
        
        self.init()
        
        guard let subject = _unwrapPossiblyTypeErasedValue(subject) else {
            self.init()
            
            return
        }
        
        if let reflected = Mirror(reflecting: subject).children
            .lazy
            .compactMap({ $1 as? (any _TaskDependencyPropertyWrapperType) })
            .first?
            .initialTaskDependencies
        {
            mergeInPlace(with: reflected)
        }
        
        if let stashed = _DependenciesStasher(from: subject)?.fetch() {
            mergeInPlace(with: stashed)
        }
        
        if let subject = subject as? _TaskDependenciesExporting {
            mergeInPlace(with: subject._exportedTaskDependencies)
        }
    }
    
    func stashable() -> TaskDependencies {
        .init(
            unkeyedValues: unkeyedValues,
            unkeyedValueTypes: unkeyedValueTypes,
            keyedValues: .init(_unsafeUniqueKeysAndValues: keyedValues.filter {
                !($0.key.base as! any TaskDependencyKey.Type).attributes.contains(.unstashable)
            })
        )
    }
    
    /// Stash the dependencies in the given subject if its an object.
    ///
    /// Provide the subject with dependencies if it conforms to `_TaskDependenciesConsuming`.
    @usableFromInline
    func _stashInOrProvideTo<T>(_ subject: T) throws {
        guard let subject = _unwrapPossiblyTypeErasedValue(subject) else {
            return
        }
        
        if let stasher = _DependenciesStasher(from: subject) {
            stasher.stash(self.stashable())
        }
        
        do {
            try (subject as? _TaskDependenciesConsuming)?.__consume(self)
            
            try Mirror(reflecting: subject).children
                .lazy
                .compactMap({ $1 as? (any _TaskDependenciesConsuming) })
                .forEach {
                    try $0.__consume(self)
                }
        } catch {
            throw _SwiftDI.Error.failedToConsumeDependencies(AnyError(erasing: error))
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
    
    func fetch() -> TaskDependencies? {
        guard let value = objc_getAssociatedObject(
            subject,
            &Self.objc_dependenciesKey
        ) else {
            return nil
        }
        
        return (value as! TaskDependencies)
    }
    
    func stash(_ dependencies: TaskDependencies) {
        objc_setAssociatedObject(
            subject,
            &Self.objc_dependenciesKey,
            dependencies,
            .OBJC_ASSOCIATION_RETAIN
        )
    }
}
