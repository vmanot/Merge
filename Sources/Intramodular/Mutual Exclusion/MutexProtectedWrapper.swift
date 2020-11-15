//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

open class AnyMutexProtectedWrapper<Value>: MutableValueConvertible {
    open var unsafelyAccessedValue: Value
    
    open var value: Value {
        get {
            return withCriticalScopeForReading({ $0 })
        } set {
            withCriticalScopeForWriting({ $0 = newValue })
        }
    }
    
    fileprivate init(unsafelyAccessedValue: Value) {
        self.unsafelyAccessedValue = unsafelyAccessedValue
    }
    
    open func withCriticalScopeForReading<T>(_: ((Value) throws -> T)) rethrows -> T {
        Never.materialize(reason: .abstract)
    }
    
    open func withCriticalScopeForWriting<T>(_: ((inout Value) throws -> T)) rethrows -> T {
        Never.materialize(reason: .abstract)
    }
}

public final class MutexProtectedWrapper<Value, Mutex: ScopedMutex>: AnyMutexProtectedWrapper<Value> {
    public let mutex: Mutex
    
    public override func withCriticalScopeForReading<T>(_ body: ((Value) throws -> T)) rethrows -> T {
        return try mutex._withCriticalScopeForReading {
            try body(unsafelyAccessedValue)
        }
    }
    
    public override func withCriticalScopeForWriting<T>(_ body: ((inout Value) throws -> T)) rethrows -> T {
        return try mutex._withCriticalScopeForWriting {
            try body(&unsafelyAccessedValue)
        }
    }
    
    public init(_ value: Value, mutex: Mutex) {
        self.mutex = mutex
        
        super.init(unsafelyAccessedValue: value)
    }
}

extension MutexProtectedWrapper {
    public func map<T>(_ transform: ((Value) throws -> T)) rethrows -> T {
        return try mutex._withCriticalScopeForReading {
            return try transform(unsafelyAccessedValue)
        }
    }
    
    public func map<Other, OtherMutex, T>(with other: MutexProtectedWrapper<Other, OtherMutex>, _ transform: ((Value, Other) throws -> T)) rethrows -> T {
        return try map { value in
            try other.map { otherValue in
                try transform(value, otherValue)
            }
        }
    }
    
    public func mutate<T>(_ mutate: ((inout Value) throws -> T)) rethrows -> T {
        return try mutex._withCriticalScopeForWriting {
            return try mutate(&unsafelyAccessedValue)
        }
    }
    
    public func mutate<Other, OtherMutex, T>(with other: MutexProtectedWrapper<Other, OtherMutex>, _ mutate: ((inout Value, inout Other) throws -> T)) rethrows -> T {
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

// MARK: - Protocol Conformances -

extension MutexProtectedWrapper where Mutex: Initiable {
    public convenience init(_ value: Value) {
        self.init(value, mutex: Mutex())
    }
}

// MARK: - Conditional Protocol Conformances -

extension MutexProtectedWrapper: CustomStringConvertible where Value: CustomStringConvertible {
    public var description: String {
        return map({ $0.description })
    }
}

extension MutexProtectedWrapper: ExpressibleByArrayLiteral where Mutex: Initiable, Value: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Value.ArrayLiteralElement
    
    public convenience init(arrayLiteral elements: ArrayLiteralElement...) {
        self.init(.init(_arrayLiteral: elements))
    }
}

extension MutexProtectedWrapper: ExpressibleByBooleanLiteral where Mutex: Initiable, Value: ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = Value.BooleanLiteralType
    
    public convenience init(booleanLiteral value: BooleanLiteralType) {
        self.init(.init(booleanLiteral: value))
    }
}

extension MutexProtectedWrapper: ExpressibleByIntegerLiteral where Mutex: Initiable, Value: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Value.IntegerLiteralType
    
    public convenience init(integerLiteral value: IntegerLiteralType) {
        self.init(.init(integerLiteral: value))
    }
}

extension MutexProtectedWrapper: BidirectionalCollection where Value: BidirectionalCollection {
    public func index(before i: Value.Index) -> Value.Index {
        return map({ $0.startIndex })
    }
}

extension MutexProtectedWrapper: Collection where Value: Collection {
    public typealias Index = Value.Index
    public typealias SubSequence = Value.SubSequence
    
    public var startIndex: Index {
        return map({ $0.startIndex })
    }
    
    public var endIndex: Index {
        return map({ $0.endIndex })
    }
    
    public subscript(_ index: Index) -> Element {
        return map({ $0[index] })
    }
    
    public func index(after i: Index) -> Index {
        return map({ $0.index(after: i) })
    }
}

extension MutexProtectedWrapper: DestructivelyMutableSequence where Mutex: Initiable, Value: ResizableSequence {
    public func forEach<T>(destructivelyMutating iterator: ((inout Element?) throws -> T)) rethrows {
        return try mutate { try $0.forEach(destructivelyMutating: iterator) }
    }
}

extension MutexProtectedWrapper: Equatable where Value: Equatable {
    public static func == (lhs: MutexProtectedWrapper, rhs: MutexProtectedWrapper) -> Bool {
        return lhs.map { lhsValue in
            rhs.map { rhsValue in
                lhsValue == rhsValue
            }
        }
    }
}

extension MutexProtectedWrapper: ExtensibleSequence where Value: ExtensibleSequence {
    public typealias ElementInsertResult = Value.ElementInsertResult
    public typealias ElementsInsertResult = Value.ElementsInsertResult
    public typealias ElementAppendResult = Value.ElementAppendResult
    public typealias ElementsAppendResult = Value.ElementsAppendResult
    
    @discardableResult
    public func insert(_ newElement: Element) -> ElementInsertResult {
        return mutate { $0.insert(newElement) }
    }
    
    @discardableResult
    public func insert<S: Sequence>(contentsOf newElements: S) -> ElementsInsertResult where S.Element == Element {
        return mutate { $0.insert(contentsOf: newElements) }
    }
    
    @discardableResult
    public func insert<C: Collection>(contentsOf newElements: C) -> ElementsInsertResult where C.Element == Element {
        return mutate { $0.insert(contentsOf: newElements) }
    }
    
    @discardableResult
    public func insert<C: BidirectionalCollection>(contentsOf newElements: C) -> ElementsInsertResult where C.Element == Element {
        return mutate { $0.insert(contentsOf: newElements) }
    }
    
    @discardableResult
    public func insert<C: RandomAccessCollection>(contentsOf newElements: C) -> ElementsInsertResult where C.Element == Element {
        return mutate { $0.insert(contentsOf: newElements) }
    }
    
    @discardableResult
    public func append(_ newElement: Element) -> ElementAppendResult {
        return mutate { $0.append(newElement) }
    }
    
    @discardableResult
    public func append<S: Sequence>(contentsOf newElements: S) -> ElementsAppendResult where S.Element == Element {
        return mutate { $0.append(contentsOf: newElements) }
    }
    
    @discardableResult
    public func append<C: Collection>(contentsOf newElements: C) -> ElementsAppendResult where C.Element == Element {
        return mutate { $0.append(contentsOf: newElements) }
    }
    
    @discardableResult
    public func append<C: BidirectionalCollection>(contentsOf newElements: C) -> ElementsAppendResult where C.Element == Element {
        return mutate { $0.append(contentsOf: newElements) }
    }
    
    @discardableResult
    public func append<C: RandomAccessCollection>(contentsOf newElements: C) -> ElementsAppendResult where C.Element == Element {
        return mutate { $0.append(contentsOf: newElements) }
    }
}

extension MutexProtectedWrapper: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        map { hasher.combine($0) }
    }
}

extension MutexProtectedWrapper: MutableCollection where Value: MutableCollection {
    public subscript(position: Index) -> Element {
        get {
            return map { $0[position] }
        }
        set {
            mutate { $0[position] = newValue }
        }
    }
}

extension MutexProtectedWrapper: MutableSequence where Value: MutableSequence {
    public func forEach<T>(mutating iterator: ((inout Element) throws -> T)) rethrows {
        return try mutate { try $0.forEach(mutating: iterator) }
    }
}

extension MutexProtectedWrapper: ResizableSequence where Mutex: Initiable, Value: ResizableSequence {
    
}

extension MutexProtectedWrapper: Sequence where Value: Sequence {
    public typealias Element = Value.Element
    public typealias Iterator = Value.Iterator
    
    public func makeIterator() -> Iterator {
        return map({ $0.makeIterator() })
    }
}

extension MutexProtectedWrapper: SequenceInitiableSequence where Mutex: Initiable, Value: SequenceInitiableSequence {
    public convenience init<S: Sequence>(_ sequence: S) where S.Element == Element {
        self.init(Value(sequence))
    }
    
    public convenience init<C: Collection>(_ collection: C) where C.Element == Element {
        self.init(Value(collection))
    }
}

// MARK: - Helpers -

public typealias DispatchMutexProtectedWrapper<Value> = MutexProtectedWrapper<Value, DispatchMutexDevice>
public typealias DispatchReentrantMutexProtectedWrapper<Value> = MutexProtectedWrapper<Value, DispatchMutexDevice>
public typealias NSMutexProtectedWrapper<Value> = MutexProtectedWrapper<Value, NSLock>
public typealias NSRecursiveMutexProtectedWrapper<Value> = MutexProtectedWrapper<Value, NSRecursiveLock>
public typealias OSUnfairMutexProtectedWrapper<Value> = MutexProtectedWrapper<Value, OSUnfairLock>

extension MutexProtectedWrapper where Value == Bool {
    public static func && <OtherMutex>(lhs: MutexProtectedWrapper, rhs: MutexProtectedWrapper<Value, OtherMutex>) -> Bool {
        return lhs.map(with: rhs) { $0 && $1 }
    }
}

extension MutexProtectedWrapper where Value: BinaryInteger {
    @inlinable
    public static func + (lhs: MutexProtectedWrapper, rhs: Value) -> Value {
        return lhs.map({ $0 + rhs })
    }
    
    @inlinable
    public static func += (lhs: MutexProtectedWrapper, rhs: Value) {
        lhs.mutate({ $0 += rhs })
    }
    
    @inlinable
    public static func - (lhs: MutexProtectedWrapper, rhs: Value) -> Value {
        return lhs.map({ $0 - rhs })
    }
    
    @inlinable
    public static func -= (lhs: MutexProtectedWrapper, rhs: Value) {
        lhs.mutate({ $0 += rhs })
    }
    
    @inlinable
    public static func * (lhs: MutexProtectedWrapper, rhs: Value) -> Value {
        return lhs.map({ $0 * rhs })
    }
    
    @inlinable
    public static func *= (lhs: MutexProtectedWrapper, rhs: Value) {
        lhs.mutate({ $0 *= rhs })
    }
}

extension MutexProtectedWrapper where Value: Equatable {
    public static func == (lhs: MutexProtectedWrapper, rhs: Value) -> Bool {
        return lhs.map({ $0 == rhs })
    }
}

public func withCriticalScope<V, M, T>(_ x: MutexProtectedWrapper<V, M>, _ body: ((inout V) throws -> T)) rethrows -> T {
    return try x.mutate { x in
        try body(&x)
    }
}

public func withCriticalScope<V1, M1, V2, M2, T>(_ x: MutexProtectedWrapper<V1, M1>, _ y: MutexProtectedWrapper<V2, M2>, _ body: ((inout V1, inout V2) throws -> T)) rethrows -> T {
    return try x.mutate(with: y) { xValue, yValue in
        try body(&xValue, &yValue)
    }
}
