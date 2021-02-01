//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

@propertyWrapper
public struct Observed<Value: ObservableObject> {
    public var wrappedValue: Value
    
    private var subscription: AnyCancellable?
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Value where EnclosingSelf.ObjectWillChangePublisher: _opaque_VoidSender {
        get {
            if object[keyPath: storageKeyPath].subscription == nil {
                object[keyPath: storageKeyPath].subscribe(_enclosingInstance: object)
            }
            
            return object[keyPath: storageKeyPath].wrappedValue
        } set {
            object[keyPath: storageKeyPath].wrappedValue = newValue
            object[keyPath: storageKeyPath].subscribe(_enclosingInstance: object)
        }
    }
    
    mutating func subscribe<EnclosingSelf: ObservableObject>(
        _enclosingInstance: EnclosingSelf
    ) where EnclosingSelf.ObjectWillChangePublisher: _opaque_VoidSender {
        subscription = wrappedValue
            .objectWillChange
            .publish(to: _enclosingInstance.objectWillChange)
            .sink()
    }
}
