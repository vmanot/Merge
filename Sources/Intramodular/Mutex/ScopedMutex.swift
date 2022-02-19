//
// Copyright (c) Vatsal Manot
//

import Swallow

public protocol ScopedMutex: Mutex {
    @discardableResult
    func withCriticalScope<T>(_: (() throws -> T)) rethrows -> T
    
    @discardableResult
    func _withCriticalScopeForReading<T>(_: (() throws -> T)) rethrows -> T
    @discardableResult
    func _withCriticalScopeForWriting<T>(_: (() throws -> T)) rethrows -> T
}


public protocol ScopedReadWriteMutex: ScopedMutex {
    @discardableResult
    func withCriticalScopeForReading<T>(_: (() throws -> T)) rethrows -> T
    @discardableResult
    func withCriticalScopeForWriting<T>(_: (() throws -> T)) rethrows -> T
}

public protocol TestableScopedMutex: ScopedMutex {
    @discardableResult
    func withCriticalScope<T>(attempt _: (() throws -> T)) rethrows -> T?
}

public protocol _opaque_MutexProtected {
    var _opaque_mutex: Mutex { get }
}

extension MutexProtected {
    public var _opaque_mutex: Merge.Mutex {
        mutex
    }
}

public protocol MutexProtected: _opaque_MutexProtected {
    associatedtype Mutex: Merge.Mutex
    
    var mutex: Mutex { get }
}

// MARK: - Implementation -

extension ScopedMutex {
    @discardableResult
    public func _withCriticalScopeForReading<T>(_ f: (() throws -> T)) rethrows -> T {
        return try withCriticalScope(f)
    }
    
    @discardableResult
    public func _withCriticalScopeForWriting<T>(_ f: (() throws -> T)) rethrows -> T {
        return try withCriticalScope(f)
    }
}

extension ScopedReadWriteMutex {
    @discardableResult
    public func withCriticalScope<T>(_ f: (() throws -> T)) rethrows -> T {
        return try withCriticalScopeForWriting(f)
    }
    
    @discardableResult
    public func _withCriticalScopeForReading<T>(_ f: (() throws -> T)) rethrows -> T {
        return try withCriticalScopeForReading(f)
    }
    
    @discardableResult
    public func _withCriticalScopeForWriting<T>(_ f: (() throws -> T)) rethrows -> T {
        return try withCriticalScopeForWriting(f)
    }
}

// MARK: - Extensions -

extension ScopedMutex {
    @discardableResult
    public func withCriticalScope<T>(if predicate: @autoclosure () -> Bool, _ body: (() throws -> T)) rethrows -> T? {
        return try withCriticalScope {
            if predicate() {
                return try body()
            } else {
                return nil
            }
        }
    }
    
    @discardableResult
    public func withCriticalScope<T, U>(unwrapping value: @autoclosure () -> T?, _ body: ((T) throws -> U)) rethrows -> U? {
        return try withCriticalScope {
            if let value = value() {
                return try body(value)
            } else {
                return nil
            }
        }
    }
}

extension ScopedReadWriteMutex {
    @discardableResult
    public func withCriticalScopeForReading<T>(execute work: @autoclosure () throws -> T) rethrows -> T {
        return try withCriticalScopeForReading(work)
    }
    @discardableResult
    public func withCriticalScopeForWriting<T>(execute work: @autoclosure () throws -> T) rethrows -> T {
        return try withCriticalScopeForWriting(work)
    }
}

extension MutexProtected where Mutex: ScopedMutex {
    @discardableResult
    public func withMutexProtectedCriticalScope<T>(_ body: (() throws -> T)) rethrows -> T {
        return try mutex.withCriticalScope(body)
    }
    
    @discardableResult
    public func withMutexProtectedCriticalScope<T>(if predicate: @autoclosure () -> Bool, _ body: (() throws -> T)) rethrows -> T? {
        return try mutex.withCriticalScope(if: predicate()) {
            return try body()
        }
    }
    
    @discardableResult
    public func withMutexProtectedCriticalScope<T, U>(unwrapping value: @autoclosure () -> T?, _ body: ((T) throws -> U)) rethrows -> U? {
        return try mutex.withCriticalScope(unwrapping: value(), body)
    }
}

extension MutexProtected where Mutex: ScopedReadWriteMutex {
    @discardableResult
    public func withMutexProtectedCriticalScopeForReading<T>(_ body: (() throws -> T)) rethrows -> T {
        return try mutex.withCriticalScopeForReading(body)
    }
    
    @discardableResult
    public func withMutexProtectedCriticalScopeForReading<T>(do expression: @autoclosure () throws -> T) rethrows -> T {
        return try mutex.withCriticalScopeForReading(expression)
    }
    
    @discardableResult
    public func withMutexProtectedCriticalScopeForWriting<T>(_ body: (() throws -> T)) rethrows -> T {
        return try mutex.withCriticalScopeForWriting(body)
    }
}

// MARK: - Helpers -

public final class MutexProtectedClosure<Mutex: ScopedMutex, Result>: MutexProtected {
    public let mutex: Mutex
    public let closure: (() -> Result)
    
    public init(mutex: Mutex, closure: @escaping (() -> Result)) {
        self.mutex = mutex
        self.closure = closure
    }
    
    public func evaluate() -> Result {
        return mutex.withCriticalScope { closure()  }
    }
}
