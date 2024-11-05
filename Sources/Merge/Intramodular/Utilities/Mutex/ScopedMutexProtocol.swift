//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A mutual exclusion device capable of scoping the execution of a function.
public protocol ScopedMutexProtocol: MutexProtocol {
    @discardableResult
    func withCriticalScope<T>(_: (() throws -> T)) rethrows -> T
    
    @discardableResult
    func _withCriticalScopeForReading<T>(_: (() throws -> T)) rethrows -> T
    @discardableResult
    func _withCriticalScopeForWriting<T>(_: (() throws -> T)) rethrows -> T
}

/// An asynchronous mutual exclusion device capable of scoping the execution of a function.
public protocol AsyncScopedMutexProtocol {
    @discardableResult
    func withCriticalScope<T>(_: (() async throws -> T)) async rethrows -> T
}

public protocol ScopedReadWriteMutexProtocol: ScopedMutexProtocol {
    @discardableResult
    func withCriticalScopeForReading<T>(_: (() throws -> T)) rethrows -> T
    @discardableResult
    func withCriticalScopeForWriting<T>(_: (() throws -> T)) rethrows -> T
}

public protocol TestableScopedMutexProtocol: ScopedMutexProtocol {
    @discardableResult
    func attemptWithCriticalScope<T>(_: (() throws -> T)) rethrows -> T?
}

// MARK: - Implementation

extension ScopedMutexProtocol {
    @discardableResult
    public func _withCriticalScopeForReading<T>(_ f: (() throws -> T)) rethrows -> T {
        return try withCriticalScope(f)
    }
    
    @discardableResult
    public func _withCriticalScopeForWriting<T>(_ f: (() throws -> T)) rethrows -> T {
        return try withCriticalScope(f)
    }
}

extension ScopedReadWriteMutexProtocol {
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

// MARK: - Extensions

extension ScopedMutexProtocol {
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

extension ScopedReadWriteMutexProtocol {
    @discardableResult
    public func withCriticalScopeForReading<T>(execute work: @autoclosure () throws -> T) rethrows -> T {
        return try withCriticalScopeForReading(work)
    }
    @discardableResult
    public func withCriticalScopeForWriting<T>(execute work: @autoclosure () throws -> T) rethrows -> T {
        return try withCriticalScopeForWriting(work)
    }
}
