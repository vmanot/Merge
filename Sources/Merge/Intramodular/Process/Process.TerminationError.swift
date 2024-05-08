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
    public struct TerminationError: CustomStringConvertible, Error, LocalizedError {
        public let process: Process
        public let status: Int32
        public let reason: Reason
        
        public enum Reason: Hashable, Sendable {
            case exit
            case uncaughtSignal
            case unknownDefault
        }
        
        public var description: String {
            errorDescription ?? "<error>"
        }
        

        public var errorDescription: String? {
            var description = "\(process.launchPath ?? "Unknown command")"
            
            if let arguments = process.arguments {
                description += " " + arguments.joined(separator: " ")
            }
            
            description += " failed because "
            
            switch reason {
                case .exit:
                    description += "it exited with code \(status)."
                case .uncaughtSignal:
                    description += "it received an uncaught signal with code \(status)."
                case .unknownDefault:
                    description += "of an unknown termination reason with code \(status)."
            }
            
            return description
        }
        
        fileprivate init(_from process: Process) {
            self.process = process
            self.status = process.terminationStatus
            self.reason = process.terminationReason.reason
        }
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
