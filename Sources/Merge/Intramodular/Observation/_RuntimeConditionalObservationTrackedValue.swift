//
// Copyright (c) Vatsal Manot
//

import Combine
#if canImport(Observation)
import Observation
#endif
import Swallow

@propertyWrapper
public final class _RuntimeConditionalObservationTrackedValue<T>: _ObservationRegistrarNotifying {
    private var wrappedValueBox: AnyMutablePropertyWrapper<T>
    private var _observationRegistrarNotifier: any _ObservationRegistrarNotifying
    
    public var wrappedValue: T {
        get {
            wrappedValueBox.wrappedValue
        }
        set {
            wrappedValueBox.wrappedValue = newValue
        }
    }
    
    public init(wrappedValue: T) {
        if #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) {
            let valueBox = _PassthroughObservationTrackedValue(wrappedValue: wrappedValue)
            
            self.wrappedValueBox = AnyMutablePropertyWrapper(valueBox)
            self._observationRegistrarNotifier = valueBox
        } else {
            self.wrappedValueBox = AnyMutablePropertyWrapper(ReferenceBox<T>(wrappedValue))
            self._observationRegistrarNotifier = _DummyObservationRegistrarNotifying()
        }
    }
    
    public func notifyingObservationRegistrar<Result>(
        _ kind: _ObservationRegistrarTrackedOperationKind,
        perform operation: () -> Result
    ) -> Result {
        _observationRegistrarNotifier.notifyingObservationRegistrar(kind, perform: operation)
    }
}

// MARK: - Auxiliary

@propertyWrapper
@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
@Observable
public final class _PassthroughObservationTrackedValue<T>: MutablePropertyWrapper, _ObservationRegistrarNotifying {
    public var wrappedValue: T
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
    
    public func notifyingObservationRegistrar<Result>(
        _ kind: _ObservationRegistrarTrackedOperationKind,
        perform operation: () -> Result
    ) -> Result {
        access(keyPath: \.wrappedValue)
        
        if kind == .mutation {
            _$observationRegistrar.willSet(self, keyPath: \.wrappedValue)
        }
        
        let result: Result = operation()
        
        if kind == .mutation {
            _$observationRegistrar.didSet(self, keyPath: \.wrappedValue)
        }
        
        return result
    }
}

public struct _DummyObservationRegistrarNotifying: _ObservationRegistrarNotifying {
    public func notifyingObservationRegistrar<Result>(
        _ kind: _ObservationRegistrarTrackedOperationKind,
        perform operation: () -> Result
    ) -> Result {
        return operation()
    }
}
