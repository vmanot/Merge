//
// Copyright (c) Vatsal Manot
//

import Swallow

extension Task where Success == Never, Failure == Never {
    /// Push a task context value onto the current stack.
    ///
    /// This will crash if it is run outside a `withTaskContextValues(...)` block.
    public static func push<T>(
        _ key: WritableKeyPath<TaskContextValues, T>,
        _ value: T
    ) {
        guard let current = _TaskContextValues_TaskLocalValues.taskContextValues as? _MutableTaskContextValues else {
            assertionFailure()
            
            return
        }
        
        var _current: TaskContextValues = current
        
        _current[keyPath: key] = value
    }
}

@discardableResult
@_transparent
public func withTaskContextValues<Result>(
    operation: (TaskContextValues) throws -> Result
) rethrows -> Result {
    let result = try operation(_TaskContextValues_TaskLocalValues.taskContextValues)
        
    return result
}

@discardableResult
public func withMutableTaskContextValues<Result>(
    operation: (TaskContextValues) throws -> Result
) rethrows -> Result {
    let current = _TaskContextValues_TaskLocalValues.taskContextValues.snapshot()
    let modifiable = _MutableTaskContextValues(current)
    
    let result = try _TaskContextValues_TaskLocalValues.$taskContextValues.withValue(modifiable) {
        try operation(modifiable)
    }
    
    modifiable.invalidate()
    
    return result
}

public protocol TaskContextValues {
    subscript<Key: TaskContextKey>(_ key: Key.Type) -> Key.Value { get set }
    
    func snapshot() -> _ResolvedTaskContextValues
}

@usableFromInline
final class _MutableTaskContextValues: TaskContextValues {
    private var lock = OSUnfairLock()
    private var base = _ResolvedTaskContextValues()
    private var invalidated: Bool = false
    
    @usableFromInline
    init(_ base: _ResolvedTaskContextValues) {
        self.base = base
    }
    
    @usableFromInline
    subscript<Key: TaskContextKey>(_ key: Key.Type) -> Key.Value {
        get {
            guard !invalidated else {
                assertionFailure()
                
                return base[key]
            }
            
            return base[key]
        } set {
            guard !invalidated else {
                assertionFailure()
    
                return
            }

            base[key] = newValue
        }
    }

    @usableFromInline
    func invalidate() {
        invalidated = true
    }
    
    @usableFromInline
    func snapshot() -> _ResolvedTaskContextValues {
        base
    }
}

public struct _ResolvedTaskContextValues: TaskContextValues {
    public var base: HeterogeneousDictionary<TaskContextValues>
    
    fileprivate init() {
        self.base = .init()
    }
    
    public subscript<Key: TaskContextKey>(
        _ key: Key.Type
    ) -> Key.Value {
        get {
            base[key] ?? key.defaultValue
        } set {
            base[key] = newValue
        }
    }

    public func snapshot() -> _ResolvedTaskContextValues {
        self
    }
}

public protocol _TaskContextKey {
    associatedtype Domain = TaskContextValues
}

public protocol TaskContextKey<Value>: _TaskContextKey, HeterogeneousDictionaryKey<TaskContextValues, Self.Value> where Domain == TaskContextValues {
    static var defaultValue: Value { get }
}

// MARK: - Internal

@usableFromInline
enum _TaskContextValues_TaskLocalValues {
    @TaskLocal public static var taskContextValues: TaskContextValues = _ResolvedTaskContextValues()
}
