//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

public struct AnyObjectWillChangePublisher: Publisher {
    public typealias Output = Void
    public typealias Failure = Never
    
    private let base: AnyPublisher<Void, Never>
        
    private init(base: AnyPublisher<Void, Never>) {
        self.base = base
    }
    
    public init(erasing publisher: ObservableObjectPublisher) {
        self.init(base: publisher.mapTo(()).eraseToAnyPublisher())
    }

    public init<Object: ObservableObject>(from object: Object) {
        self.init(base: object.objectWillChange.mapTo(()).eraseToAnyPublisher())
    }
        
    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        base.receive(subscriber: subscriber)
    }
}

// MARK: - Supplementary -

extension AnyObjectWillChangePublisher {
    public static var empty: Self {
        .init(base: Empty().eraseToAnyPublisher())
    }
}
