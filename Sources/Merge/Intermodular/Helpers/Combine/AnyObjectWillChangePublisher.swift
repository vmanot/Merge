//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public final class AnyObjectWillChangePublisher: Publisher {
    public typealias Output = Void
    public typealias Failure = Never
    
    private let base: AnyPublisher<Void, Never>
    private let _send: () -> Void
    
    fileprivate init<P: Publisher>(
        publisher: P
    ) where P.Failure == Never {
        self.base = publisher.mapTo(()).eraseToAnyPublisher()
        self._send = {
            do {
                try cast(publisher, to: _opaque_VoidSender.self).send()
            } catch {
                runtimeIssue(error)
            }
        }
    }
    
    public convenience init(
        erasing publisher: ObservableObjectPublisher
    ) {
        self.init(publisher: publisher)
    }
    
    public convenience init<Object: ObservableObject>(
        from object: Object
    ) {
        self.init(publisher: object.objectWillChange)
    }
    
    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Output, S.Failure == Failure {
        base.receive(subscriber: subscriber)
    }
    
    public convenience init?(from object: AnyObject) {
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
    public static var empty: AnyObjectWillChangePublisher {
        AnyObjectWillChangePublisher(publisher: Empty<Void, Never>().eraseToAnyPublisher())
    }
}

extension AnyObjectWillChangePublisher: _opaque_VoidSender {
    public func send() {
        _send()
    }
}
