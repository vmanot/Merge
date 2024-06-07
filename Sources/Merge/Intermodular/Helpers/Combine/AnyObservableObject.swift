//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

public final class AnyObservableObject<Output, Failure: Error>: ObservableObject {
    public let base: any ObservableObject
    public let objectWillChange: AnyPublisher<Output, Failure>
    
    public init<T: ObservableObject>(
        _ base: T
    ) where T.ObjectWillChangePublisher.Output == Output, T.ObjectWillChangePublisher.Failure == Failure
    {
        self.base = base
        self.objectWillChange = base.objectWillChange.eraseToAnyPublisher()
    }
    
    public init(
        _ base: any _opaque_ObservableObject
    ) where Output == AnyObjectWillChangePublisher.Output, Failure == AnyObjectWillChangePublisher.Failure  {
        self.base = base as (any ObservableObject)
        self.objectWillChange = base._opaque_objectWillChange.eraseToAnyPublisher()
    }
    
    fileprivate init<T: ObservableObject>(
        _erasing base: T
    ) where Output == AnyObjectWillChangePublisher.Output, Failure == AnyObjectWillChangePublisher.Failure  {
        self.base = base as (any ObservableObject)
        self.objectWillChange = base._opaque_objectWillChange.eraseToAnyPublisher()
    }
}

extension AnyObservableObject where Output == Void, Failure == Never {
    public static var empty: AnyObservableObject {
        .init(_EmptyObservableObject())
    }
}

// MARK: - Auxiliary

private final class _EmptyObservableObject: ObservableObject {
    
}

extension ObservableObject {
    public func _eraseToAnyObservableObject() -> _AnyObservableObject {
        _AnyObservableObject(_erasing: self)
    }
}

public typealias _AnyObservableObject = AnyObservableObject<AnyObjectWillChangePublisher.Output, AnyObjectWillChangePublisher.Failure>
