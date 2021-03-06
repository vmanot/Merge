//
// Copyright (c) Vatsal Manot
//

import Swift

public struct TaskResultPublisher<Upstream: Task>: SingleOutputPublisher {
    public typealias Output = TaskResult<Upstream.Success, Upstream.Error>
    public typealias Failure = Never
    
    private let upstream: Upstream
    
    public init(upstream: Upstream) {
        self.upstream = upstream
    }
    
    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Output, S.Failure == Failure {
        if let result = upstream.result {
            _ = subscriber.receive(result)
            
            subscriber.receive(completion: .finished)
        } else {
            upstream.objectWillChange
                .compactMap(TaskResult.init)
                .receive(subscriber: subscriber)
        }
    }
}

// MARK: - API -

extension Task {
    public var resultPublisher: TaskResultPublisher<Self> {
        .init(upstream: self)
    }
}
