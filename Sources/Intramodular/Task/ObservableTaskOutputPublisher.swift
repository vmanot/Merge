//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

public struct ObservableTaskOutputPublisher<Base: ObservableTask>: Publisher {
    public typealias Output = TaskOutput<Base.Success, Base.Error>
    public typealias Failure = TaskFailure<Base.Error>

    private let base: Base

    public init(_ base: Base) {
        self.base = base
    }

    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
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

        base.start()

        base.objectWillChange
            .filter({ $0 != .idle })
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
            .receive(subscriber: subscriber)
    }
}

// MARK: - API -

extension ObservableTask {
    public var outputPublisher: ObservableTaskOutputPublisher<Self> {
        ObservableTaskOutputPublisher(self)
    }
}
