//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

/// The status of a task.
public enum TaskStatus<Success, Error: Swift.Error> {
    case idle
    case started
    case canceled
    case success(Success)
    case error(Error)
}

// MARK: - Extensions -

extension TaskStatus {
    public var isIdle: Bool {
        if case .idle = self {
            return true
        } else {
            return false
        }
    }
    
    public var isActive: Bool {
        switch self {
            case .started:
                return true
            default:
                return false
        }
    }
    
    public var isTerminal: Bool {
        switch self {
            case .success, .canceled, .error:
                return true
            default:
                return false
        }
    }
    
    public var isOutput: Bool {
        TaskStatusDescription(self).isOutput
    }
    
    public var isFailure: Bool {
        TaskStatusDescription(self).isFailure
    }
    
    public var isCompletion: Bool {
        TaskStatusDescription(self).isCompletion
    }
}

extension TaskStatus {
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

extension TaskStatus {
    public var output: TaskOutput<Success, Error>? {
        switch self {
            case .started:
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
                self = .started
            case .success(let success):
                self = .success(success)
        }
    }
    
    public var failure: TaskFailure<Error>? {
        switch self {
            case .canceled:
                return .canceled
            case .error(let error):
                return .error(error)
            default:
                return nil
        }
    }
    
    public init(_ failure: TaskFailure<Error>) {
        switch failure {
            case .canceled:
                self = .canceled
            case .error(let error):
                self = .error(error)
        }
    }
}

extension TaskStatus {
    public func map<T>(_ transform: (Success) -> T) -> TaskStatus<T, Error> {
        switch self {
            case .idle:
                return .idle
            case .started:
                return .started
            case .canceled:
                return .canceled
            case .success(let success):
                return .success(transform(success))
            case .error(let error):
                return .error(error)
        }
    }
    
    public func mapError<T: Swift.Error>(_ transform: (Error) -> T) -> TaskStatus<Success, T> {
        switch self {
            case .idle:
                return .idle
            case .started:
                return .started
            case .canceled:
                return .canceled
            case .success(let success):
                return .success(success)
            case .error(let error):
                return .error(transform(error))
        }
    }
}

// MARK: - Protocol Conformances -

extension TaskStatus: Equatable where Success: Equatable, Error: Equatable {
    
}

extension TaskStatus: Hashable where Success: Hashable, Error: Hashable {
    
}

// MARK: - Auxiliary Implementation -

extension AnyTask {
    public enum _GeneralStatusComparison {
        case active
        case inactive
        
        public static func == (lhs: Self, rhs: Status) -> Bool {
            switch lhs {
                case .active:
                    return rhs.isActive
                case .inactive:
                    return !rhs.isActive
            }
        }
        
        public static func == (lhs: Status, rhs: Self) -> Bool {
            rhs == lhs
        }
    }
    
    public enum _ExactStatusComparison {
        case idle
        case started
        case canceled
        case success
        case error
        
        public static func == (lhs: Self, rhs: Status) -> Bool {
            switch (lhs, rhs) {
                case (.idle, .idle):
                    return true
                case (.started, .started):
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
    }
}

// MARK: - Helpers -

extension TaskProtocol {
    public var isActive: Bool {
        status.isActive
    }
    
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

extension TaskStatus {
    public init(_ status: Result<Success, Error>) {
        switch status {
            case .success(let value):
                self = .success(value)
            case .failure(let error):
                self = .error(error)
        }
    }
}

extension Result {
    public init?(_ status: TaskStatus<Success, Failure>) {
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
