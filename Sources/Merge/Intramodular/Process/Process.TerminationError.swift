//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

#if os(macOS) || targetEnvironment(macCatalyst)
public struct ProcessTerminationError: Error, Hashable, LocalizedError {
    public let process: Process
    public let status: Int32
    public let reason: Reason
        
    @available(macCatalyst, unavailable)
    public init(_from process: Process) {
        self.process = process
        self.status = process.terminationStatus
        self.reason = process.terminationReason.reason
    }
}
#else
public struct ProcessTerminationError: Error, Hashable, LocalizedError {
    public let status: Int32
    public let reason: Reason
}
#endif

#if os(macOS) || targetEnvironment(macCatalyst)
@available(macCatalyst, unavailable)
extension ProcessTerminationError: CustomStringConvertible {
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
}

extension Process {
    public static func _makeDescriptionPrefix(
        launchPath: String?,
        arguments: [String]?
    ) -> String {
        var description = "\(launchPath ?? "Unknown command")"
        
        if let arguments = arguments {
            description += " " + arguments.joined(separator: " ")
        }
        
        return description
    }
}

#endif

// MARK: - Auxiliary

extension ProcessTerminationError {
    public enum Reason: Hashable, Sendable {
        case exit
        case uncaughtSignal
        case unknownDefault
    }
}

// MARK: - Supplementary

#if os(macOS) || targetEnvironment(macCatalyst)
extension Process {
    public typealias TerminationError = ProcessTerminationError
}

@available(macCatalyst, unavailable)
extension Process {
    public var terminationError: TerminationError? {
        assert(!isRunning)
        
        guard terminationStatus != 0 else {
            return nil
        }
        
        return TerminationError(_from: self)
    }
}

@available(macCatalyst, unavailable)
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
