//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift
import SwiftUI

public enum TaskStatusDescription: CustomDebugStringConvertible, Hashable {
    case idle
    case active
    case paused
    case canceled
    case success
    case error(OpaqueError)
    
    public var debugDescription: String {
        switch self {
            case .idle:
                return "idle"
            case .active:
                return "active"
            case .paused:
                return "paused"
            case .canceled:
                return "canceled"
            case .success:
                return "success"
            case .error:
                return "error"
        }
    }
}

extension TaskStatusDescription {
    public var isTerminal: Bool {
        switch self {
            case .success, .canceled, .error:
                return true
            default:
                return false
        }
    }

    public var isOutput: Bool {
        switch self {
            case .idle:
                return false
            case .active, .paused, .success:
                return true
            case .canceled, .error:
                return false
        }
    }
    
    public var isFailure: Bool {
        switch self {
            case .idle:
                return false
            case .active, .paused, .success:
                return false
            case .canceled, .error:
                return true
        }
    }
}

extension TaskStatusDescription {
    public var isCompletion: Bool {
        switch self {
            case .idle, .active, .paused:
                return false
            case .canceled, .success, .error:
                return true
        }
    }
}

extension TaskStatusDescription {
    public var isActive: Bool {
        switch self {
            case .active:
                return true
            default:
                return false
        }
    }
    
    public init<Success, Error: Swift.Error>(_ status: TaskStatus<Success, Error>) {
        switch status {
            case .idle:
                self = .idle
            case .active:
                self = .active
            case .paused:
                self = .paused
            case .canceled:
                self = .canceled
            case .success:
                self = .success
            case .error(let error):
                self = .error(.init(error))
        }
    }
}

// MARK: - Auxiliary

extension TaskStatusDescription {
    public struct OpaqueError: Error, Hashable {
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
        case success
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
                    case .success:
                        if case .success = lhs {
                            return true
                        } else {
                            return false
                        }
                    case .failure:
                        return lhs.isFailure
                }
            } else {
                switch rhs {
                    case .idle:
                        return true
                    case .active:
                        return false
                    case .success:
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
            !(lhs == rhs)
        }
    }
}

extension TaskStatus {
    @_disfavoredOverload
    public static func == (lhs: Self, rhs: TaskStatusDescription.Comparison) -> Bool {
        TaskStatusDescription(lhs) == rhs
    }
    
    @_disfavoredOverload
    public static func != (lhs: Self, rhs: TaskStatusDescription.Comparison) -> Bool {
        TaskStatusDescription(lhs) != rhs
    }
}
