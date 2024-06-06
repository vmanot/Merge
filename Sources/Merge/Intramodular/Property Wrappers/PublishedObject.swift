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
        
    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance enclosingInstance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, PublishedObject>
    ) -> Value where EnclosingSelf.ObjectWillChangePublisher: _opaque_VoidSender {
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
        lhs.wrappedValue == rhs.wrappedValue
    }
}

extension PublishedObject: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}

extension PublishedObject: Decodable where Value: Decodable & ObservableObject {
    public convenience init(from decoder: Decoder) throws {
        try self.init(wrappedValue: WrappedValue(from: decoder))
    }
}

extension PublishedObject: Encodable where Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

extension PublishedObject: ObservableObject {
    public var objectWillChange: AnyObjectWillChangePublisher {
        objectWillChangeRelay.objectWillChange
    }
}

// MARK: - Auxiliary

public final class ObjectWillChangePublisherRelay<Source, Destination>: ObservableObject {
    private let _objectWillChange = ObservableObjectPublisher()
    
    public var objectWillChange: AnyObjectWillChangePublisher {
        .init(erasing: _objectWillChange)
    }
    
    public var isUninitialized: Bool {
        source == nil && destination == nil
    }
    
    @Weak
    public var source: Source? {
        didSet {
            if let oldValue = oldValue as? AnyObject, let newValue = source as? AnyObject, oldValue === newValue {
                return
            }

            updateSubscription()
        }
    }
    
    @Weak
    public var destination: Destination? {
        didSet {
            if let oldValue = oldValue as? AnyObject, let newValue = destination as? AnyObject, oldValue === newValue {
                return
            }
            
            updateSubscription()
        }
    }
    
    private var destinationObjectWillChangePublisher: _opaque_VoidSender?
    private var subscription: AnyCancellable?
    
    public init(source: Source? = nil, destination: Destination? = nil) {
        self.source = source
        self.destination = destination
    }
    
    public convenience init() where Source == Any, Destination == Any {
        self.init(source: nil, destination: nil)
    }
    
    public func send() {
        guard let destinationObjectWillChangePublisher else {
            if subscription != nil, destination != nil {
                updateSubscription()
            }
            
            return
        }
        
        if !Thread.isMainThread {
            runtimeIssue("Publishing changes from background threads is not allowed.")
        }
        
        destinationObjectWillChangePublisher.send()
    }
    
    private func updateSubscription() {
        destinationObjectWillChangePublisher = nil
        subscription?.cancel()
        subscription = nil
        
        guard
            let destination = toObservableObject(destination),
            let destinationObjectWillChange = (destination.objectWillChange as any Publisher) as? _opaque_VoidSender
        else {
            return
        }

        destinationObjectWillChangePublisher = destinationObjectWillChange
        
        guard let source = toObservableObject(source) else {
            return
        }

        assert(source !== destination)
                
        subscription = source
            .eraseObjectWillChangePublisher()
            .publish(to: _objectWillChange)
            .publish(to: destinationObjectWillChange)
            .sink()
    }
    
    private func toObservableObject(_ thing: Any?) -> (any ObservableObject)? {
        do {
            let object: (any ObservableObject)?
            
            if let wrappedValue = thing as? (any OptionalProtocol) {
                if let _wrappedValue = wrappedValue._wrapped as? any ObservableObject {
                    object = _wrappedValue
                } else {
                    object = nil
                }
            } else {
                object = try cast(destination, to: (any ObservableObject).self)
            }
            
            return object
        } catch {
            assertionFailure()
            
            return nil
        }
    }
}
