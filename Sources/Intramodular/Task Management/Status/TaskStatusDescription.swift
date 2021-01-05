//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUIX

public enum TaskStatusDescription: Hashable {
    case idle
    case started
    case progress(Progress?)
    case canceled
    case success
    case error(OpaqueError)
}

extension TaskStatusDescription {
    public var isOutput: Bool {
        switch self {
            case .idle:
                return false
            case .started, .progress, .success:
                return true
            case .canceled, .error:
                return false
        }
    }
    
    public var isFailure: Bool {
        switch self {
            case .idle:
                return false
            case .started, .progress, .success:
                return false
            case .canceled, .error:
                return true
        }
    }
}

extension TaskStatusDescription {
    public var isCompletion: Bool {
        switch self {
            case .idle:
                return false
            case .started:
                return false
            case .progress:
                return false
            case .canceled:
                return true
            case .success:
                return true
            case .error:
                return true
        }
    }
}

extension TaskStatusDescription {
    public var isActive: Bool {
        switch self {
            case .started, .progress:
                return true
            default:
                return false
        }
    }
    
    public init<Success, Error: Swift.Error>(_ status: TaskStatus<Success, Error>) {
        switch status {
            case .idle:
                self = .idle
            case .started:
                self = .started
            case .canceled:
                self = .canceled
            case .success:
                self = .success
            case .error(let error):
                self = .error(.init(error))
        }
    }
}

// MARK: - Auxiliary -

extension TaskStatusDescription {
    public struct OpaqueError: Hashable {
        public let localizedDescription: String
        
        fileprivate init(_ error: Error) {
            self.localizedDescription = error.localizedDescription
        }
    }
}

extension TaskStatusDescription {
    public enum Comparison {
        case idle
        case active
        case failure
        
        public static func == (
            lhs: TaskStatusDescription?,
            rhs: Self
        ) -> Bool {
            if let lhs = lhs {
                switch rhs {
                    case .idle:
                        return lhs == .idle
                    case .active:
                        return lhs.isActive
                    case .failure:
                        return lhs.isFailure
                }
            } else {
                switch rhs {
                    case .idle:
                        return true
                    case .active:
                        return false
                    case .failure:
                        return false
                }
            }
        }
        
        public static func != (
            lhs: TaskStatusDescription?,
            rhs: Self
        ) -> Bool {
            if let lhs = lhs {
                switch rhs {
                    case .idle:
                        return lhs != .idle
                    case .active:
                        return !lhs.isActive
                    case .failure:
                        return !lhs.isFailure
                }
            } else {
                switch rhs {
                    case .idle:
                        return false
                    case .active:
                        return true
                    case .failure:
                        return true
                }
            }
        }
    }
}
