//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

private enum PrefixUntilAfterOutput<Output> {
    case output(Output)
    case terminate
    
    public var outputValue: Output? {
        if case let .output(output) = self {
            return output
        } else {
            return nil
        }
    }
    
    public var isTerminate: Bool {
        if case .terminate = self {
            return true
        } else {
            return false
        }
    }
}

extension Publisher {
    public func prefixUntil(
        after predicate: @escaping (Output) -> Bool
    ) -> AnyPublisher<Output, Failure> {
        flatMap { output -> AnyPublisher<PrefixUntilAfterOutput<Output>, Failure> in
            if predicate(output) {
                return Publishers.Concatenate(
                    prefix: Just(PrefixUntilAfterOutput.output(output))
                        .setFailureType(to: Failure.self),
                    suffix: Just(PrefixUntilAfterOutput.terminate)
                        .setFailureType(to: Failure.self)
                ).eraseToAnyPublisher()
            } else {
                return Just(PrefixUntilAfterOutput.output(output))
                    .setFailureType(to: Failure.self)
                    .eraseToAnyPublisher()
            }
        }
        .prefix(while: { !$0.isTerminate })
        .compactMap({ $0.outputValue })
        .eraseToAnyPublisher()
    }
}
