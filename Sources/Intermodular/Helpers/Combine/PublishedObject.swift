//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

/// A type that forwards updates published from the `ObservableObject` annotated with this wrapper.
@propertyWrapper
public final class PublishedObject<Value>: PropertyWrapper {
    public let _publisher = PassthroughSubject<Void, Never>()
    
    @MutableValueBox
    public var wrappedValue: Value
    
    public var projectedValue: AnyPublisher<Value, Never> {
        _publisher
            .compactMap { [weak self] in
                self?.wrappedValue
            }
            .eraseToAnyPublisher()
    }
    
    private var subscription: AnyCancellable?
    
    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, PublishedObject>
    ) -> Value where EnclosingSelf.ObjectWillChangePublisher: _opaque_VoidSender {
        get {
            if object[keyPath: storageKeyPath].subscription == nil {
                object[keyPath: storageKeyPath].subscribe(_enclosingInstance: object)
            }
            
            return object[keyPath: storageKeyPath].wrappedValue
        } set {
            object.objectWillChange.send()
            
            object[keyPath: storageKeyPath].wrappedValue = newValue
            object[keyPath: storageKeyPath].subscribe(_enclosingInstance: object)
        }
    }
    
    private func subscribe<EnclosingSelf: ObservableObject>(
        _enclosingInstance: EnclosingSelf
    ) where EnclosingSelf.ObjectWillChangePublisher: _opaque_VoidSender {
        do {
            subscription?.cancel()
            subscription = nil
            
            let object: (any ObservableObject)?
            
            if let wrappedValue = wrappedValue as? (any OptionalProtocol) {
                if let _wrappedValue = wrappedValue._wrapped {
                    object = try! cast(_wrappedValue, to: (any ObservableObject).self)
                } else {
                    object = nil
                }
            } else {
                object = try cast(wrappedValue, to: (any ObservableObject).self)
            }
            
            guard let object else {
                return 
            }
           
            subscription = object
                .eraseObjectWillChangePublisher()
                .publish(to: _enclosingInstance.objectWillChange)
                .publish(to: _publisher)
                .sink()
        } catch {
            assertionFailure(error)
        }
    }
    
    public init(
        wrappedValue: Value
    ) where Value: ObservableObject {
        self.wrappedValue = wrappedValue
    }
    
    public init<WrappedValue: ObservableObject>(
        wrappedValue: WrappedValue?
    ) where Optional<WrappedValue> == Value  {
        self.wrappedValue = wrappedValue
    }
    
    public init<P: PropertyWrapper>(
        wrappedValue: P
    ) where P.WrappedValue == Value {
        self._wrappedValue = .init(AnyMutablePropertyWrapper(unsafelyAdapting: wrappedValue))
    }
    
    public init<P: MutablePropertyWrapper>(
        wrappedValue: P
    ) where P.WrappedValue == Value {
        self._wrappedValue = .init(wrappedValue)
    }
}

@available(*, deprecated, renamed: "PublishedObject")
public typealias Observed<Value: ObservableObject> = PublishedObject<Value>

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
