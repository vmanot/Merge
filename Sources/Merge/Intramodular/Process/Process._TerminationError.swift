//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swallow

extension Process {
    public var terminationError: _TerminationError? {
        if self.terminationStatus == 0 {
            return nil
        }
        
        return _TerminationError(process: self)
    }
}

extension Process {
    public struct _TerminationError: Error, LocalizedError {
        public let status: Int32
        public let reason: Reason
        
        public enum Reason {
            case exit, uncaughtSignal, unknownDefault
        }
        
        public var errorDescription: String? {
            switch reason {
                case .exit:
                    return "Exited with code \(status)."
                case .uncaughtSignal:
                    return "Uncaught signal, exited with code \(status)."
                case .unknownDefault:
                    return "Unknown termination reason, exited with code \(status)."
            }
        }
    }
}

private extension Process._TerminationError {
    init(process: Process) {
        self.status = process.terminationStatus
        self.reason = process.terminationReason.reason
    }
}

private extension Process.TerminationReason {
    var reason: Process._TerminationError.Reason {
        switch self {
            case .exit:
                return .exit
            case .uncaughtSignal:
                return .uncaughtSignal
            @unknown default:
                return .unknownDefault
        }
    }
}

#endif
