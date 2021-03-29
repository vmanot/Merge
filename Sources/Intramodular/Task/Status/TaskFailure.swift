//
// Copyright (c) Vatsal Manot
//

import Swift

/// The failure of a task.
public enum TaskFailure<Error: Swift.Error>: Swift.Error {
    case canceled
    case error(Error)
}

extension TaskFailure {
    public init?<Success>(_ status: TaskStatus<Success, Error>) {
        if let failure = status.failure {
            self = failure
        } else {
            return nil
        }
    }
}

// MARK: - Conformances -

extension TaskFailure: Equatable where Error: Equatable {
    
}

extension TaskFailure: Hashable where Error: Hashable {
    
}

// MARK: - Helpers -

extension Subscribers.Completion {
    public static func failure<Error>(
        _ error: Error
    ) -> Self where Failure == TaskFailure<Error> {
        .failure(.error(error))
    }
}
