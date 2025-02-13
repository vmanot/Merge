//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

#if os(macOS) || targetEnvironment(macCatalyst)
public struct ProcessTerminationError: Error, Hashable, LocalizedError {
    public let process: Process
    public let stdout: String?
    public let stderr: String?
    public let status: Int32
    public let reason: Reason
        
    @available(macCatalyst, unavailable)
    public init(
        _from process: Process,
        stdout: String? = nil,
        stderr: String? = nil
    ) {
        self.process = process
        self.stdout = stdout
        self.stderr = stderr
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
        var message = "Process terminated with status \(status)"
        
        if let executablePath = process.executableURL?.path {
            message += " (\(executablePath))"
        }
        
        message += "\nReason: \(reason)"
        
        if let stderr = stderr, !stderr.isEmpty {
            message += "\nStandard Error: \(stderr.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
        
        if let stdout = stdout, !stdout.isEmpty {
            message += "\nStandard Output: \(stdout.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
        
        return message
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
