//
// Copyright (c) Vatsal Manot
//

import Combine
import FoundationX
import SwiftUI

public enum _AsyncElementAccessor<Element>: Publisher {
    public typealias Output = Element
    public typealias Failure = Never
    
    public struct _AnonymousPushPull {
        let upstream: AnyPublisher<Element, Never>
        let push: (Element) -> Void
        
        public init(upstream: AnyPublisher<Element, Never>, push: @escaping (Element) -> Void) {
            self.upstream = upstream
            self.push = push
        }
        
        public init(upstream: some Publisher<Element, Never>, push: @escaping (Element) -> Void) {
            self.upstream = upstream.eraseToAnyPublisher()
            self.push = push
        }
    }
    
    case anonymous(_AnonymousPushPull)
    case multiReaderSubjectChild(_MultiReaderSubject<Element, Never>.Child)
    
    public init(
        _ binding: Binding<Element>
    ) {
        self = .anonymous(
            .init(
                upstream: Deferred(createPublisher: { Just(binding.wrappedValue) }).eraseToAnyPublisher(),
                push: {
                    binding.wrappedValue = $0
                }
            )
        )
    }
    
    public init<P: AnyObject & MutablePropertyWrapper<Element>>(
        _ wrapper: P
    ) {
        self = .anonymous(
            .init(
                upstream: Deferred {
                    Just(wrapper.wrappedValue)
                }
                    .eraseToAnyPublisher(),
                push: {
                    var wrapper = wrapper
                    
                    wrapper.wrappedValue = $0
                }
            )
        )
    }
    
    public func send(_ value: Element) {
        switch self {
            case .anonymous(let accessor):
                accessor.push(value)
            case .multiReaderSubjectChild(let subject):
                subject.send(value)
        }
    }
    
    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Element, S.Failure == Never {
        switch self {
            case .anonymous(let source):
                source.upstream.receive(subscriber: subscriber)
            case .multiReaderSubjectChild(let subject):
                subject.receive(subscriber: subscriber)
        }
    }
}

extension PublishedAsyncBinding {
    public func map<T>(
        get: @escaping (Value) -> T,
        set: @escaping (inout Value, T) -> Void
    ) -> PublishedAsyncBinding<T> {
        let cache = InMemorySingleValueCache<T>()
        let initialValue: T = get(value)
        
        cache.store(initialValue)
        
        let subject = self.subject.child()
        
        let accessor = _AsyncElementAccessor<T>._AnonymousPushPull(
            upstream: subject.map(get).eraseToAnyPublisher(),
            push: { [weak self] (newValue: T) in
                guard let `self` = self else {
                    assertionFailure()
                    
                    return
                }
                
                var rootValue = self.value
                
                set(&rootValue, newValue)
                
                subject.send(rootValue)
            }
        )
        
        return PublishedAsyncBinding<T>(
            accessor: .anonymous(accessor),
            cache: cache,
            defaultValue: { initialValue },
            debounceInterval: 0
        )
    }
    
    public func map<T>(
        _ keyPath: WritableKeyPath<Value, T>
    ) -> PublishedAsyncBinding<T> {
        map(
            get: {
                $0[keyPath: keyPath]
            },
            set: {
                $0[keyPath: keyPath] = $1
            }
        )
    }
}
