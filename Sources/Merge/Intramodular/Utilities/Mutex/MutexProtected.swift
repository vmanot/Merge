//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

open class AnyMutexProtected<Value> {
    open var unsafelyAccessedValue: Value
    
    fileprivate init(unsafelyAccessedValue: Value) {
        self.unsafelyAccessedValue = unsafelyAccessedValue
    }
    
    open var wrappedValue: Value {
        fatalError()
    }
    
    open func withCriticalScope<T>(_ read: ((Value) throws -> T)) rethrows -> T {
        Never.materialize(reason: .abstract)
    }
    
    open func withCriticalRegion<T>(_ mutate: ((inout Value) throws -> T)) rethrows -> T {
        Never.materialize(reason: .abstract)
    }
    
    public final func mutate<T>(_ mutate: ((inout Value) throws -> T)) rethrows -> T {
        try withCriticalRegion(mutate)
    }
}

/// A property wrapper that guards access to a stored value using a mutex.
///
/// Notes:
/// - `MutexProtected` checks whether its enclosing self is a `_MutexProtectedType` and if so, uses the enclosing self's mutex to protect the stored value.
@propertyWrapper
public final class MutexProtected<Value, Mutex: ScopedMutexProtocol>: AnyMutexProtected<Value>, @unchecked Sendable {
    public private(set) var mutex: Mutex
    
    override public var wrappedValue: Value {
        get {
            mutex._withCriticalScopeForReading({ unsafelyAccessedValue })
        }
    }
    
    public var assignedValue: Value {
        get {
            wrappedValue
        }
        set {
            mutate({ $0 = newValue })
        }
    }
    
    public static subscript<EnclosingSelf>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: KeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: KeyPath<EnclosingSelf, MutexProtected>
    ) -> Value {
        get {
            if let _instance = instance as? any _MutexProtectedType {
                assert(Mutex.self == AnyLock.self)  // using the enclosing instance's mutex is only supported when `Mutex` is a type-erased lock.
                
                guard let mutex = _instance.mutex as? Mutex else {
                    assertionFailure()
                    
                    return instance[keyPath: storageKeyPath].wrappedValue
                }
                
                instance[keyPath: storageKeyPath].mutex = mutex
            }
            
            return instance[keyPath: storageKeyPath].wrappedValue
        }
    }
    
    public var projectedValue: MutexProtected {
        self
    }
    
    public init(wrappedValue: Value, mutex: Mutex) {
        self.mutex = mutex
        
        super.init(unsafelyAccessedValue: wrappedValue)
    }
    
    public init(wrappedValue: Value) where Mutex: Initiable {
        self.mutex = .init()
        
        super.init(unsafelyAccessedValue: wrappedValue)
    }
    
    public convenience init<T>() where Mutex: Initiable, Value == Optional<T> {
        self.init(wrappedValue: nil)
    }
    
    public init(wrappedValue: Value) where Mutex == AnyLock {
        self.mutex = .init(OSUnfairLock())
        
        super.init(unsafelyAccessedValue: wrappedValue)
    }
    
    override public func withCriticalScope<T>(_ read: ((Value) throws -> T)) rethrows -> T {
        try mutex._withCriticalScopeForReading {
            try read(unsafelyAccessedValue)
        }
    }
    
    override public func withCriticalRegion<T>(_ mutate: ((inout Value) throws -> T)) rethrows -> T {
        try mutex._withCriticalScopeForWriting {
            try mutate(&unsafelyAccessedValue)
        }
    }
}

extension MutexProtected {
    public func map<T>(_ transform: ((Value) throws -> T)) rethrows -> T {
        return try mutex._withCriticalScopeForReading {
            return try transform(unsafelyAccessedValue)
        }
    }
    
    public func map<Other, OtherMutex, T>(with other: MutexProtected<Other, OtherMutex>, _ transform: ((Value, Other) throws -> T)) rethrows -> T {
        return try map { value in
            try other.map { otherValue in
                try transform(value, otherValue)
            }
        }
    }
    
    public func mutate<Other, OtherMutex, T>(with other: MutexProtected<Other, OtherMutex>, _ mutate: ((inout Value, inout Other) throws -> T)) rethrows -> T {
        return try self.mutate { value in
            try other.withCriticalRegion { otherValue in
                try mutate(&value, &otherValue)
            }
        }
    }
    
    public func exchange(with newValue: Value) -> Value {
        return mutex._withCriticalScopeForWriting {
            let oldValue = unsafelyAccessedValue
            unsafelyAccessedValue = newValue
            return oldValue
        }
    }
    
    public func update(with transform: ((Value) throws -> Value)) rethrows -> (oldValue: Value, newValue: Value) {
        return try mutex._withCriticalScopeForWriting {
            let oldValue = unsafelyAccessedValue
            let newValue = try transform(oldValue)
            unsafelyAccessedValue = newValue
            return (oldValue, newValue)
        }
    }
}

extension MutexProtected: Equatable where Value: Equatable {
    public static func == (lhs: MutexProtected, rhs: MutexProtected) -> Bool {
        lhs.withCriticalRegion { lhs in
            rhs.withCriticalRegion { rhs in
                lhs == rhs
            }
        }
    }
}

extension MutexProtected: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        withCriticalScope {
            $0.hash(into: &hasher)
        }
    }
}
