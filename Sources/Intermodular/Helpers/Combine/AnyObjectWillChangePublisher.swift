//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

public struct AnyObjectWillChangePublisher: Publisher {
    public typealias Output = Void
    public typealias Failure = Never
    
    private let base: AnyPublisher<Void, Never>
    
    public init<Object: ObservableObject>(from object: Object) {
        base = object.objectWillChange.map({ _ in () }).eraseToAnyPublisher()
    }
    
    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        base.receive(subscriber: subscriber)
    }
}
