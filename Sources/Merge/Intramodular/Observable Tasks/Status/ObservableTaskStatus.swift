//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public protocol ObservableTaskStatusType<Success, Error> {
    associatedtype Success
    associatedtype Error 
}

/// The status of a task.
@frozen
public enum ObservableTaskStatus<Success, Error: Swift.Error>: ObservableTaskStatusType {
    case idle
    case active
    case paused
    case canceled
    case success(Success)
    case error(Error)
}

// MARK: - Extensions

extension ObservableTaskStatus {
    public var isTerminal: Bool {
        switch self {
            case .success, .canceled, .error:
                return true
            default:
                return false
        }
    }
    
    public var isOutput: Bool {
        ObservableTaskStatusDescription(self).isOutput
    }
    
    public var isFailure: Bool {
        ObservableTaskStatusDescription(self).isFailure
    }
    
    public var isCompletion: Bool {
        ObservableTaskStatusDescription(self).isCompletion
    }
}

extension ObservableTaskStatus {
    public var successValue: Success? {
        if case let .success(success) = self {
            return success
        } else {
            return nil
        }
    }
    
    public var errorValue: Error? {
        if case let .error(error) = self {
            return error
        } else {
            return nil
        }
    }
}

extension ObservableTaskStatus {
    public var output: TaskOutput<Success, Error>? {
        switch self {
            case .active:
                return .started
            case .success(let success):
                return .success(success)
            default:
                return nil
        }
    }
    
    public init(_ output: TaskOutput<Success, Error>) {
        switch output {
            case .started:
                self = .active
            case .success(let success):
                self = .success(success)
        }
    }
    
    public var failure: ObservableTaskFailure<Error>? {
        switch self {
            case .canceled:
                return .canceled
            case .error(let error):
                return .error(error)
            default:
                return nil
        }
    }
    
    public init(_ failure: ObservableTaskFailure<Error>) {
        switch failure {
            case .canceled:
                self = .canceled
            case .error(let error):
                self = .error(error)
        }
    }
}

extension ObservableTaskStatus {
    public func map<T>(_ transform: (Success) -> T) -> ObservableTaskStatus<T, Error> {
        switch self {
            case .idle:
                return .idle
            case .active:
                return .active
            case .paused:
                return .paused
            case .canceled:
                return .canceled
            case .success(let success):
                return .success(transform(success))
            case .error(let error):
                return .error(error)
        }
    }
    
    public func mapError<T: Swift.Error>(_ transform: (Error) -> T) -> ObservableTaskStatus<Success, T> {
        switch self {
            case .idle:
                return .idle
            case .active:
                return .active
            case .paused:
                return .paused
            case .canceled:
                return .canceled
            case .success(let success):
                return .success(success)
            case .error(let error):
                return .error(transform(error))
        }
    }
}

// MARK: - Conformances

extension ObservableTaskStatus: Equatable where Success: Equatable, Error: Equatable {
    
}

extension ObservableTaskStatus: Hashable where Success: Hashable, Error: Hashable {
    
}

extension ObservableTaskStatus: Sendable where Success: Sendable {
    
}

// MARK: - Auxiliary

extension AnyTask {
    public enum _GeneralStatusComparison {
        case inactive
        case finished
        
        public static func == (lhs: Self, rhs: Status) -> Bool {
            switch (lhs, rhs) {
                case (.inactive, .idle):
                    return true
                case (.inactive, .active):
                    return false
                case (.inactive, .paused):
                    return true
                case (.inactive, .canceled):
                    return true
                case (.inactive, .success):
                    return true
                case (.inactive, .error):
                    return true
                    
                case (.finished, .idle):
                    return false
                case (.finished, .active):
                    return false
                case (.finished, .paused):
                    return false
                case (.finished, .canceled):
                    return true
                case (.finished, .success):
                    return true
                case (.finished, .error):
                    return true
            }
        }
        
        public static func == (lhs: Status, rhs: Self) -> Bool {
            rhs == lhs
        }
        
        public static func != (lhs: Self, rhs: Status) -> Bool {
            !(lhs == rhs)
        }
        
        public static func != (lhs: Status, rhs: Self) -> Bool {
            !(lhs == rhs)
        }
        
        public static func == (lhs: Optional<Status>, rhs: Self) -> Bool {
            guard let lhs = lhs else {
                return false
            }
            
            return lhs == rhs
        }
    }
    
    public enum _ExactStatusComparison {
        case idle
        case active
        case paused
        case canceled
        case success
        case error
        
        public static func == (lhs: Self, rhs: Status) -> Bool {
            switch (lhs, rhs) {
                case (.idle, .idle):
                    return true
                case (.active, .active):
                    return true
                case (.paused, .paused):
                    return true
                case (.canceled, .canceled):
                    return true
                case (.success, .success):
                    return true
                case (.error, .error):
                    return true
                default:
                    return false
            }
        }
        
        public static func == (lhs: Status, rhs: Self) -> Bool {
            rhs == lhs
        }
        
        public static func != (lhs: Status, rhs: Self) -> Bool {
            !(rhs == lhs)
        }
        
        public static func == (lhs: Optional<Status>, rhs: Self) -> Bool {
            guard let lhs = lhs else {
                return false
            }
            
            return lhs == rhs
        }
    }
}

// MARK: - Helpers

extension ObservableTask {
    public var hasSucceeded: Bool {
        if case .success = statusDescription {
            return true
        } else {
            return false
        }
    }
    
    public var isCanceled: Bool {
        statusDescription == .canceled
    }
    
    public var hasFailed: Bool {
        if case .error = statusDescription {
            return true
        } else {
            return false
        }
    }
    
    public var hasEnded: Bool {
        status.isTerminal
    }
}

extension ObservableTaskStatus {
    public init(_ status: Result<Success, Error>) {
        switch status {
            case .success(let value):
                self = .success(value)
            case .failure(let error):
                self = .error(error)
        }
    }
    
    public init(_ status: Result<TaskOutput<Success, Error>, ObservableTaskFailure<Error>>) {
        switch status {
            case .success(let output): do {
                switch output {
                    case .started:
                        self = .active
                    case .success(let value):
                        self = .success(value)
                }
            }
            case .failure(let failure): do {
                switch failure {
                    case .canceled:
                        self = .canceled
                    case .error(let error):
                        self = .error(error)
                }
            }
        }
    }
}

extension Result {
    public init?(_ status: ObservableTaskStatus<Success, Failure>) {
        switch status {
            case .success(let success):
                self = .success(success)
            case .error(let error):
                self = .failure(error)
            default:
                return nil
        }
    }
}
