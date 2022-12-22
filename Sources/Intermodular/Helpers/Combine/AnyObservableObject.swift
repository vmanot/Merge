//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

public final class AnyObservableObject<Output, Failure: Error>: ObservableObject {
    public let base: AnyObject
    public let objectWillChange: AnyPublisher<Output, Failure>
    
    public init<T: ObservableObject>(_ base: T) where T.ObjectWillChangePublisher.Output == Output, T.ObjectWillChangePublisher.Failure == Failure
    {
        self.base = base
        self.objectWillChange = base.objectWillChange.eraseToAnyPublisher()
    }
    
    public init(_ base: _opaque_ObservableObject) where Output == AnyObjectWillChangePublisher.Output, Failure == AnyObjectWillChangePublisher.Failure  {
        self.base = base as AnyObject
        self.objectWillChange = base._opaque_objectWillChange.eraseToAnyPublisher()
    }
}

extension AnyObservableObject where Output == Void, Failure == Never {
    public static var empty: AnyObservableObject {
        .init(_EmptyObservableObject())
    }
}

// MARK: - Auxiliary -

private final class _EmptyObservableObject: ObservableObject {
    
}
