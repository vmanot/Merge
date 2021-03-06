//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

/// The output of a task.
public enum TaskOutput<Success, Error: Swift.Error> {
    case started
    case success(Success)
}

extension TaskOutput {
    public var successValue: Success? {
        TaskStatus(self).successValue
    }
    
    public var isTerminal: Bool {
        switch self {
            case .success:
                return true
            default:
                return false
        }
    }
    
    public func map<T>(_ transform: (Success) -> T) -> TaskOutput<T, Error> {
        switch self {
            case .started:
                return .started
            case .success(let success):
                return .success(transform(success))
        }
    }
}

// MARK: - Protocol Conformances -

extension TaskOutput: Equatable where Success: Equatable {
    
}

extension TaskOutput: Hashable where Success: Hashable {
    
}
