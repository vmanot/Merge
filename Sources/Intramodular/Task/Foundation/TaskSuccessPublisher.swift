//
// Copyright (c) Vatsal Manot
//

import Swift

public struct TaskSuccessPublisher<Upstream: Task>: SingleOutputPublisher {
    public typealias Output = Upstream.Success
    public typealias Failure = Upstream.Error
    
    private let upstream: Upstream
    
    public init(upstream: Upstream) {
        self.upstream = upstream
    }
    
    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Output, S.Failure == Failure {
         upstream
            .prefixUntil(after: { $0.isTerminal })
            .mapResult({ TaskStatus($0) })
            .compactMap({ Result($0) })
            .flatMap({ $0.publisher })
            .receive(subscriber: subscriber)
    }
}

// MARK: - API -

extension Task {
    public var successPublisher: TaskSuccessPublisher<Self> {
        .init(upstream: self)
    }
}
