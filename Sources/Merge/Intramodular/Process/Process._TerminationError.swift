//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swallow

extension Process {
    public var terminationError: TerminationError? {
        guard terminationStatus != 0 else {
            return nil
        }
        
        return TerminationError(_from: self)
    }
}

extension Process {
    public struct TerminationError: Error, LocalizedError {
        public let status: Int32
        public let reason: Reason
        
        public enum Reason: Hashable, Sendable {
            case exit
            case uncaughtSignal
            case unknownDefault
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

extension Process.TerminationError {
    fileprivate init(_from process: Process) {
        self.status = process.terminationStatus
        self.reason = process.terminationReason.reason
    }
}

extension Process.TerminationReason {
    package var reason: Process.TerminationError.Reason {
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
