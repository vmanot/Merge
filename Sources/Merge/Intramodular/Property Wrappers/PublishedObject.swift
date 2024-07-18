//
// Copyright (c) Vatsal Manot
//

import Foundation
import Combine
import Swallow

/// A type that forwards updates published from the `ObservableObject` annotated with this wrapper.
@propertyWrapper
public final class PublishedObject<Value>: PropertyWrapper {
    public typealias _SelfType = PublishedObject<Value>
    
    /// In case `_wrappedValue` is backed by an `ObservableArray` or some shit.
    private let _wrappedValueBoxWillChangeRelay: ObjectWillChangePublisherRelay<Any, Any>?
    private let _assignmentPublisher = PassthroughSubject<Void, Never>()
    
    private let objectWillChangeRelay = ObjectWillChangePublisherRelay()
    
    @MutableValueBox
    public var _wrappedValue: Value
    
    public var wrappedValue: Value {
        get {
            _wrappedValue
        } set {
            objectWillChangeRelay.send()
            
            _wrappedValue = newValue
            
            _assignmentPublisher.send()
        }
    }
    
    public var projectedValue: _SelfType {
        self
    }
    
    public var assignmentPublisher: AnyPublisher<Value, Never> {
        _assignmentPublisher
            .compactMap { [weak self] in
                self?.wrappedValue
            }
            .eraseToAnyPublisher()
    }
    
    @MainActor
    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance enclosingInstance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, PublishedObject>
    ) -> Value {
        get {
            let published = enclosingInstance[keyPath: storageKeyPath]
            
            published.setUpObjectWillChangeRelays(from: published.wrappedValue, to: enclosingInstance)
            
            return published.wrappedValue
        } set {
            let published = enclosingInstance[keyPath: storageKeyPath]
            
            published.setUpObjectWillChangeRelays(from: newValue, to: enclosingInstance)
            
            published.wrappedValue = newValue
        }
    }
    
    private func setUpObjectWillChangeRelays<T>(
        from value: WrappedValue,
        to enclosingInstance: T
    ) {
        if objectWillChangeRelay.isUninitialized {
            objectWillChangeRelay.source = value
            objectWillChangeRelay.destination = enclosingInstance
        }
        
        if let wrappedBoxRelay = _wrappedValueBoxWillChangeRelay, wrappedBoxRelay.isUninitialized {
            assert(wrappedBoxRelay.source != nil)
            
            wrappedBoxRelay.destination = enclosingInstance
        }
    }
    
    public init(
        wrappedValue: Value
    ) where Value: ObservableObject {
        self._wrappedValue = wrappedValue
        self._wrappedValueBoxWillChangeRelay = nil
    }
    
    public init<Element: ObservableObject>(
        wrappedValue: [Element]
    ) where Value == [Element] {
        let array = ObservableArray(wrappedValue)
        
        self.__wrappedValue = .init(array)
        
        _wrappedValueBoxWillChangeRelay = ObjectWillChangePublisherRelay()
        _wrappedValueBoxWillChangeRelay?.source = array
    }
    
    public init<WrappedValue: ObservableObject>(
        wrappedValue: WrappedValue?
    ) where Optional<WrappedValue> == Value  {
        self._wrappedValue = wrappedValue
        self._wrappedValueBoxWillChangeRelay = nil
    }
    
    public init<P: PropertyWrapper>(
        wrappedValue: P
    ) where P.WrappedValue == Value {
        self.__wrappedValue = .init(AnyMutablePropertyWrapper(unsafelyAdapting: wrappedValue))
        self._wrappedValueBoxWillChangeRelay = nil
    }
    
    public init<P: MutablePropertyWrapper>(
        wrappedValue: P
    ) where P.WrappedValue == Value {
        self.__wrappedValue = .init(wrappedValue)
        self._wrappedValueBoxWillChangeRelay = nil
    }
}

// MARK: - Conditional Conformances

extension PublishedObject: Equatable where Value: Equatable {
    public static func == (lhs: PublishedObject, rhs: PublishedObject) -> Bool {
        lhs._wrappedValue == rhs._wrappedValue
    }
}

extension PublishedObject: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_wrappedValue)
    }
}

extension PublishedObject: Decodable where Value: Decodable & ObservableObject {
    public convenience init(from decoder: Decoder) throws {
        try self.init(wrappedValue: WrappedValue(from: decoder))
    }
}

extension PublishedObject: Encodable where Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        try _wrappedValue.encode(to: encoder)
    }
}

extension PublishedObject: ObservableObject {
    public var objectWillChange: AnyObjectWillChangePublisher {
        objectWillChangeRelay.objectWillChange
    }
}
