//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

public struct ObservableTaskOutputPublisher<Base: ObservableTask>: Publisher {
    public typealias Output = TaskOutput<Base.Success, Base.Error>
    public typealias Failure = ObservableTaskFailure<Base.Error>
    
    private let base: Base
    
    public init(_ base: Base) {
        self.base = base
    }
    
    public func receive(
        subscriber: some Subscriber<Output, Failure>
    ) {
        defer {
            base.start()
        }
        
        guard !base.status.isTerminal else {
            if let output = base.status.output {
                return Just(output)
                    .setFailureType(to: Failure.self)
                    .receive(subscriber: subscriber)
            } else if let failure = base.status.failure {
                return Fail<Output, Failure>(error: failure)
                    .receive(subscriber: subscriber)
            } else {
                return assertionFailure()
            }
        }
        
        base.objectDidChange
            .filter({ $0.isTerminal })
            .setFailureType(to: Failure.self)
            .flatMap({ status -> AnyPublisher<Output, Failure> in
                if let output = status.output {
                    return Just(output)
                        .setFailureType(to: Failure.self)
                        .eraseToAnyPublisher()
                } else if let failure = status.failure {
                    return Fail<Output, Failure>(error: failure)
                        .eraseToAnyPublisher()
                } else {
                    assertionFailure()
                    
                    return Fail<Output, Failure>(error: .canceled)
                        .eraseToAnyPublisher()
                }
            })
            .handleCancel {
                guard base.status.isTerminal else {
                    runtimeIssue(CancellationError())
                    
                    return
                }
            }
            .receive(subscriber: subscriber)
    }
}

// MARK: - API

extension ObservableTask {
    public var outputPublisher: ObservableTaskOutputPublisher<Self> {
        ObservableTaskOutputPublisher(self)
    }
}
