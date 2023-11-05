//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

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
    
    public init?(from object: AnyObject) {
        let observableObject: (any ObservableObject)?
        
        if let wrappedValue = object as? (any OptionalProtocol) {
            if let _wrappedValue = wrappedValue._wrapped {
                observableObject = try! cast(_wrappedValue, to: (any ObservableObject).self)
            } else {
                observableObject = nil
            }
        } else {
            observableObject = try? cast(object, to: (any ObservableObject).self)
        }
        
        guard let observableObject = observableObject else {
            return nil
        }
        
        self.init(from: observableObject)
    }
}

// MARK: - Supplementary -

extension AnyObjectWillChangePublisher {
    public static var empty: Self {
        .init(base: Empty().eraseToAnyPublisher())
    }
}
