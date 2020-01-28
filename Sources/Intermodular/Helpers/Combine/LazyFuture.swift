//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift

public final class LazyFuture<Output, Failure: Error>: Publisher  {
    public typealias Promise = (Result<Output, Failure>) -> Void
    
    public let cancellables = Cancellables()
    
    private let base: Deferred<Future<Output, Failure>>
    
    public init(_ attemptToFulfill: @escaping (@escaping Promise) -> Void) {
        self.base = .init {
            Future(attemptToFulfill)
        }
    }
    
    public final func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        base.receive(subscriber: subscriber)
    }
}
