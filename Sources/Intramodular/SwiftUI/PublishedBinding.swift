//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift
import SwiftUI

@propertyWrapper
public struct PublishedBinding<Value> {
    struct _Binding<T> {
        let get: () -> T
        let set: (T) -> Void
        
        var wrappedValue: T {
            get {
                get()
            } nonmutating set {
                set(newValue)
            }
        }
    }
    
    private let base: _Binding<Value?>
    
    public var cacheLastNonNilValue: Bool
    public var lastNonNilValue: Value?
    public var baseWasDestroyed: Bool = false
    
    public var wrappedValue: Value {
        get {
            guard !baseWasDestroyed else {
                assert(base.wrappedValue == nil)
                
                return lastNonNilValue!
            }
            
            return base.wrappedValue ?? lastNonNilValue!
        } set {
            guard !baseWasDestroyed else {
                assert(base.wrappedValue == nil)
                
                lastNonNilValue = newValue
                
                return
            }
            
            if cacheLastNonNilValue {
                if let existingValue = base.wrappedValue {
                    lastNonNilValue = existingValue
                    base.wrappedValue = newValue
                } else {
                    baseWasDestroyed = true
                    lastNonNilValue = newValue
                }
            } else {
                base.wrappedValue = newValue
            }
        }
    }
    
    private init(_ binding: _Binding<Value>) {
        self.base = .init(
            get: { binding.wrappedValue },
            set: { binding.wrappedValue = $0! }
        )
        self.cacheLastNonNilValue = false
    }
    
    private init(unsafelyUnwrapping binding: _Binding<Value?>) {
        self.base = binding
        self.cacheLastNonNilValue = true
        self.lastNonNilValue = binding.wrappedValue
    }
    
    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Value where EnclosingSelf.ObjectWillChangePublisher == ObservableObjectPublisher {
        get {
            let result = object[keyPath: storageKeyPath].wrappedValue
            
            return result
        } set {
            object.objectWillChange.send()
            
            object[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}

extension PublishedBinding {
    public static func unsafelyUnwrapping<T>(
        _ root: T,
        _ keyPath: ReferenceWritableKeyPath<T, Value?>
    ) -> Self {
        Self(
            unsafelyUnwrapping: _Binding(
                get: { root[keyPath: keyPath] },
                set: { root[keyPath: keyPath] = $0 }
            )
        )
    }
    
    public static func unsafelyUnwrapping(
        _ binding: @escaping () -> Binding<Value?>
    ) -> Self {
        Self(unsafelyUnwrapping: _Binding(get: { binding().wrappedValue }, set: { binding().wrappedValue = $0 }))
    }
}
