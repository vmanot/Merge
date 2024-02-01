//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public final class _AsyncObjectWillChangePublisher: Publisher, Sendable {
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
}

extension _AsyncObjectWillChangePublisher {
    public func withCriticalScope(
        _ f: @escaping (ObservableObjectPublisher) -> Void
    ) {
        let shouldExit = base.withGuaranteedSubscriberCount { count -> Bool in
            guard count == 0 else {
                return false
            }

            f(self.base.upstream)
            
            return true
        }
        
        if shouldExit {
            return
        }
        
        MainThreadScheduler.shared.schedule {
            f(self.base.upstream)
        }
    }
}
