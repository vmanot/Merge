//
// Copyright (c) Vatsal Manot
//

import Swift

public struct TaskResultPublisher<Upstream: ObservableTask>: SingleOutputPublisher {
    public typealias Output = TaskResult<Upstream.Success, Upstream.Error>
    public typealias Failure = Never
    
    private let upstream: Upstream
    
    public init(upstream: Upstream) {
        self.upstream = upstream
    }
    
    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Output, S.Failure == Failure {
        if let result = TaskResult(upstream.status) {
            _ = subscriber.receive(result)
            
            subscriber.receive(completion: .finished)
        } else {
            upstream
                .objectDidChange
                .compactMap(TaskResult.init)
                .receive(subscriber: subscriber)
        }
    }
}

