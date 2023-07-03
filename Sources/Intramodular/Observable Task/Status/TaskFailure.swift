//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Combine
import Swallow

/// The failure of a task.
public enum TaskFailure<Error: Swift.Error>: _ErrorX, HashEquatable {
    case canceled
    case error(Error)
    
    public var traits: ErrorTraits {
        switch self {
            case .canceled:
                assertionFailure()
                
                return []
            case .error(let error):
                return AnyError(erasing: error).traits
        }
    }
    
    public init?(_catchAll error: AnyError) throws {
        guard let _error = try cast(Error.self, to: any _ErrorX.Type.self).init(_catchAll: error) else {
            return nil
        }
        
        self = try .error(cast(_error))
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
            case .canceled:
                hasher.combine(AnyError(erasing: CancellationError()))
            case .error(let error):
                hasher.combine(AnyError(erasing: error))
        }
    }
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

extension AnyError {
    public init(from failure: TaskFailure<Error>) {
        switch failure {
            case .canceled:
                self.init(erasing: CancellationError())
            case .error(let error):
                self.init(erasing: error)
        }
    }
}

// MARK: - Helpers

extension Subscribers.Completion {
    public static func failure<Error>(
        _ error: Error
    ) -> Self where Failure == TaskFailure<Error> {
        .failure(.error(error))
    }
}
