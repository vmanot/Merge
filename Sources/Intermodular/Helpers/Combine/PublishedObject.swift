//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

/// A type that forwards updates published from the `ObservableObject` annotated with this wrapper.
@propertyWrapper
public final class PublishedObject<Value>: PropertyWrapper {
    public typealias _SelfType = PublishedObject<Value>
    
    /// In case `_wrappedValue` is backed by an `ObservableArray` or some shit.
    private let _wrappedValueBoxWillChangeRelay: ObjectWillChangePublisherRelay?
    private let _assignmentPublisher = PassthroughSubject<Void, Never>()
    
    private let objectWillChangeRelay = ObjectWillChangePublisherRelay()
    
    @MutableValueBox
    public var _wrappedValue: Value
    
    public var wrappedValue: Value {
        get {
            _wrappedValue
        } set {
            objectWillChange.send()
            
            _wrappedValue = newValue
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
            let propertyWrapper = enclosingInstance[keyPath: storageKeyPath]
            
            if propertyWrapper.objectWillChangeRelay.source == nil {
                Task { @MainActor in
                    enclosingInstance.objectWillChange.send()
                }
                
                propertyWrapper.objectWillChangeRelay.source = propertyWrapper.wrappedValue
                propertyWrapper.objectWillChangeRelay.destination = enclosingInstance
            }
            
            if let wrappedValueBoxRelay = propertyWrapper._wrappedValueBoxWillChangeRelay, wrappedValueBoxRelay.destination == nil {
                wrappedValueBoxRelay.destination = enclosingInstance
            }
            
            return propertyWrapper.wrappedValue
        } set {
            let propertyWrapper = enclosingInstance[keyPath: storageKeyPath]

            enclosingInstance.objectWillChange.send()
                        
            propertyWrapper.wrappedValue = newValue
            
            propertyWrapper._assignmentPublisher.send()

            propertyWrapper.objectWillChangeRelay.source = propertyWrapper.wrappedValue
            propertyWrapper.objectWillChangeRelay.destination = enclosingInstance
            propertyWrapper._wrappedValueBoxWillChangeRelay?.destination = enclosingInstance
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
    public var objectWillChange: ObservableObjectPublisher {
        objectWillChangeRelay.objectWillChange
    }
}

// MARK: - Auxiliary

public final class ObjectWillChangePublisherRelay: ObservableObject {
    @Weak
    public var source: Any? {
        didSet {
            if let oldValue = oldValue as? AnyObject, let newValue = source as? AnyObject, oldValue === newValue {
                return
            }

            updateSubscription()
        }
    }
    
    @Weak
    public var destination: Any? {
        didSet {
            if let oldValue = oldValue as? AnyObject, let newValue = destination as? AnyObject, oldValue === newValue {
                return
            }
            
            updateSubscription()
        }
    }
    
    private var subscription: AnyCancellable?
    
    public init(source: Any? = nil, destination: Any? = nil) {
        self.source = source
        self.destination = destination
    }
    
    public func updateSubscription() {
        subscription?.cancel()
        subscription = nil
        
        guard
            let source = toObservableObject(source),
            let destination = toObservableObject(destination),
            let destinationObjectWillChange = (destination.objectWillChange as any Publisher) as? _opaque_VoidSender
        else {
            return
        }
        
        subscription = source
            .eraseObjectWillChangePublisher()
            .publish(to: objectWillChange)
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
