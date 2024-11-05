//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

/// A type that is explicitly protected by a mutex.
///
/// This type is a work-in-progress. Do not use this type directly in your code.
public protocol _MutexProtectedType: Sendable {
    associatedtype Mutex: Merge.MutexProtocol
    
    var mutex: Mutex { get }
}

extension _MutexProtectedType where Mutex: ScopedMutexProtocol {
    public typealias _MutexProtected<Value> = Merge.MutexProtected<Value, Mutex>
}

// MARK: - Extensions

extension _MutexProtectedType where Mutex: ScopedMutexProtocol {
    @discardableResult
    public func withMutexProtectedCriticalScope<T>(
        _ body: (
    () throws -> T
        )
    ) rethrows -> T {
        return try mutex.withCriticalScope(body)
    }
    
    @discardableResult
    public func withMutexProtectedCriticalScope<T>(
        if predicate: @autoclosure () -> Bool,
        _ body: (() throws -> T)
    ) rethrows -> T? {
        return try mutex.withCriticalScope(if: predicate()) {
            return try body()
        }
    }
    
    @discardableResult
    public func withMutexProtectedCriticalScope<T, U>(
        unwrapping value: @autoclosure () -> T?,
        _ body: ((T) throws -> U)
    ) rethrows -> U? {
        return try mutex.withCriticalScope(unwrapping: value(), body)
    }
}

extension _MutexProtectedType where Mutex: ScopedReadWriteMutexProtocol {
    @discardableResult
    public func withMutexProtectedCriticalScopeForReading<T>(
        _ body: (
    () throws -> T
        )
    ) rethrows -> T {
        return try mutex.withCriticalScopeForReading(body)
    }
    
    @discardableResult
    public func withMutexProtectedCriticalScopeForReading<T>(
        do expression: @autoclosure () throws -> T
    ) rethrows -> T {
        return try mutex.withCriticalScopeForReading(expression)
    }
    
    @discardableResult
    public func withMutexProtectedCriticalScopeForWriting<T>(
        _ body: (() throws -> T)
    ) rethrows -> T {
        return try mutex.withCriticalScopeForWriting(body)
    }
}
