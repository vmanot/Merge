//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

public enum _ShellProcessExecutionError: LocalizedError {
    case errorWithLogInfo(String, underlyingError: Error)
    case openingLogError(Error, underlyingError: Error)
    
    public var errorDescription: String? {
        description
    }
}

// MARK: - Conformances

extension _ShellProcessExecutionError: CustomStringConvertible {
    public var description: String {
        switch self {
            case .errorWithLogInfo(
                let logInfo,
                underlyingError: let underlyingError
            ):
                return """
        An error occurred: \(underlyingError.localizedDescription). Here is the contents of the log file:
        """ + logInfo
                
            case .openingLogError(let error, underlyingError: let underlyingError):
                return """
        An error occurred: \(underlyingError.localizedDescription)
        
        Also, an error occurred while attempting to open the log file: \(error.localizedDescription)
        """
        }
    }
}
