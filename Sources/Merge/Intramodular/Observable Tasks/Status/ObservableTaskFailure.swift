//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Combine
import Swallow

protocol ObservableTaskFailureProtocol {
    var _opaque_error: (any Swift.Error)? { get }
}

extension ObservableTaskFailure: ObservableTaskFailureProtocol {
    public var _opaque_error: (any Swift.Error)? {
        switch self {
            case .canceled:
                return nil
            case .error(let error):
                return error
        }
    }
}

/// An enumeration that represents the source of task failure.
@frozen
public enum ObservableTaskFailure<Error: Swift.Error>: _ErrorX, HashEquatable {
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
        guard let _error = try cast(Error.self, to: (any _ErrorX.Type).self).init(_catchAll: error) else {
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

// MARK: - Initializers

extension ObservableTaskFailure {
    public init?<Success>(_ status: ObservableTaskStatus<Success, Error>) {
        if let failure = status.failure {
            self = failure
        } else {
            return nil
        }
    }
}

// MARK: - Supplementary

extension AnyError {
    public init(from failure: ObservableTaskFailure<Error>) {
        switch failure {
            case .canceled:
                self.init(erasing: CancellationError())
            case .error(let error):
                self.init(erasing: error)
        }
    }
}

extension Subscribers.Completion {
    public static func failure<Error>(
        _ error: Error
    ) -> Self where Failure == ObservableTaskFailure<Error> {
        .failure(.error(error))
    }
}
