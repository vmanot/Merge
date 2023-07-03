//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public final class _AsyncObjectWillChangePublisher: Publisher {
    public typealias Output = ObservableObjectPublisher.Output
    public typealias Failure = ObservableObjectPublisher.Failure
    
    private let base: Publishers.CountSubscribers<ObservableObjectPublisher>
    
    public init() {
        self.base = .init(upstream: .init())
    }
    
    public func receive<S: Subscriber<Output, Failure>>(
        subscriber: S
    ) {
        base.receive(subscriber: subscriber)
    }
        
    public func withCriticalScope(
        _ f: @escaping (ObservableObjectPublisher) -> Void
    ) {
        var exit = false
        
        base.withGuaranteedSubscriberCount { count in
            guard count == 0 else {
                return
            }
            
            f(self.base.upstream)
            
            exit = true
        }
        
        guard !exit else {
            return
        }
        
        MainThreadScheduler.shared.schedule {
            f(self.base.upstream)
        }
    }
}
