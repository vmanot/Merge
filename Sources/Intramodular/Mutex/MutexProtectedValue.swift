//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

open class AnyMutexProtectedValue<Value> {
    open var unsafelyAccessedValue: Value
    
    fileprivate init(unsafelyAccessedValue: Value) {
        self.unsafelyAccessedValue = unsafelyAccessedValue
    }
    
    open var wrappedValue: Value {
        fatalError()
    }
    
    open func mutate<T>(_ mutate: ((inout Value) throws -> T)) rethrows -> T {
        Never.materialize(reason: .abstract)
    }
}

@propertyWrapper
public final class MutexProtectedValue<Value, Mutex: ScopedMutex>: AnyMutexProtectedValue<Value>, @unchecked Sendable {
    public private(set) var mutex: Mutex
    
    override public var wrappedValue: Value {
        get {
            mutex._withCriticalScopeForReading({ unsafelyAccessedValue })
        }
    }
    
    public var assignedValue: Value {
        get {
            wrappedValue
        } set {
            mutate({ $0 = newValue })
        }
    }
    
    public static subscript<EnclosingSelf>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: KeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: KeyPath<EnclosingSelf, MutexProtectedValue>
    ) -> Value {
        get {
            if let _instance = instance as? _opaque_MutexProtected, let mutex = _instance._opaque_mutex as? Mutex {
                instance[keyPath: storageKeyPath].mutex = mutex
            }
            
            return instance[keyPath: storageKeyPath].wrappedValue
        }
    }
    
    public var projectedValue: MutexProtectedValue {
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
    
    public init(wrappedValue: Value) where Mutex == AnyLock {
        self.mutex = .init(OSUnfairLock())
        
        super.init(unsafelyAccessedValue: wrappedValue)
    }
    
    override public func mutate<T>(_ mutate: ((inout Value) throws -> T)) rethrows -> T {
        return try mutex._withCriticalScopeForWriting {
            return try mutate(&unsafelyAccessedValue)
        }
    }
}

extension MutexProtectedValue {
    public func map<T>(_ transform: ((Value) throws -> T)) rethrows -> T {
        return try mutex._withCriticalScopeForReading {
            return try transform(unsafelyAccessedValue)
        }
    }
    
    public func map<Other, OtherMutex, T>(with other: MutexProtectedValue<Other, OtherMutex>, _ transform: ((Value, Other) throws -> T)) rethrows -> T {
        return try map { value in
            try other.map { otherValue in
                try transform(value, otherValue)
            }
        }
    }
    
    public func mutate<Other, OtherMutex, T>(with other: MutexProtectedValue<Other, OtherMutex>, _ mutate: ((inout Value, inout Other) throws -> T)) rethrows -> T {
        return try self.mutate { value in
            try other.mutate { otherValue in
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
