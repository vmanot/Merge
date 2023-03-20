//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift
import SwiftUI

@dynamicMemberLookup
@propertyWrapper
public final class PublishedBinding<Value>: ObservableObject {
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
            objectWillChange.send()
            
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
    
    public var projectedValue: Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
    }
    
    private init(
        binding: _Binding<Value?>,
        cacheLastNonNilValue: Bool
    ) {
        self.base = binding
        self.cacheLastNonNilValue = cacheLastNonNilValue
    }
    
    private convenience init(
        unsafelyUnwrapping binding: _Binding<Value?>
    ) {
        self.init(binding: binding, cacheLastNonNilValue: true)

        self.lastNonNilValue = binding.wrappedValue
    }
    
    public static subscript<EnclosingSelf>(
        _enclosingInstance object: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, PublishedBinding<Value>>
    ) -> Value {
        get {
            let result = object[keyPath: storageKeyPath].wrappedValue
            
            return result
        } set {
            if let object = (object as? (any ObservableObject)) {
                if let objectWillChange = ((object.objectWillChange as any Publisher) as? _opaque_VoidSender) {
                    objectWillChange.send()
                }
            }
            
            object[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
    
    public subscript<Subject>(
        dynamicMember keyPath: WritableKeyPath<Value, Subject>
    ) -> PublishedBinding<Subject> {
        get {
            PublishedBinding<Subject>(
                unsafelyUnwrapping: PublishedBinding<Subject>._Binding(
                    get: {
                        self.wrappedValue[keyPath: keyPath]
                    },
                    set: {
                        self.base.wrappedValue?[keyPath: keyPath] = $0!
                    }
                )
            )
        }
    }
}

extension PublishedBinding {
    public convenience init(
        get: @escaping @Sendable () -> Value,
        set: @escaping @Sendable (Value) -> Void
    ) {
        self.init(
            binding: .init(get: { get() }, set: { set($0!) }),
            cacheLastNonNilValue: false
        )
    }
    
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
        Self(
            unsafelyUnwrapping: _Binding(
                get: { binding().wrappedValue },
                set: { binding().wrappedValue = $0 }
            )
        )
    }
    
    @_disfavoredOverload
    public static func unsafelyUnwrapping(
        _ binding: @autoclosure @escaping () -> Binding<Value?>
    ) -> Self {
        Self(
            unsafelyUnwrapping: _Binding(
                get: { binding().wrappedValue },
                set: { binding().wrappedValue = $0 }
            )
        )
    }
}

extension Binding {
    public init(_ binding: PublishedBinding<Value>) {
        self.init(
            get: { binding.wrappedValue },
            set: { binding.wrappedValue = $0 }
        )
    }
}
