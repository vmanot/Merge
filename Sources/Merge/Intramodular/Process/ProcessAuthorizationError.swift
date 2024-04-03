//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Security
import Swift

public enum ProcessAuthorizationError: Error {
    case invalidSet
    case invalidRef
    case invalidTag
    case invalidPointer
    case denied
    case canceled
    case interactionNotAllowed
    case `internal`
    case externalizeNotAllowed
    case internalizeNotAllowed
    case invalidFlags
    case toolExecuteFailure
    case toolEnvironmentError
    case badAddress
    
    public init?(status: OSStatus) {
        switch status {
            case noErr:
                return nil
            case errAuthorizationSuccess:
                return nil
            case errAuthorizationInvalidSet:
                self = .invalidSet
            case errAuthorizationInvalidRef:
                self = .invalidRef
            case errAuthorizationInvalidTag:
                self = .invalidTag
            case errAuthorizationInvalidPointer:
                self = .invalidPointer
            case errAuthorizationDenied:
                self = .denied
            case errAuthorizationCanceled:
                self = .canceled
            case errAuthorizationInteractionNotAllowed:
                self = .interactionNotAllowed
            case errAuthorizationInternal:
                self = .internal
            case errAuthorizationExternalizeNotAllowed:
                self = .externalizeNotAllowed
            case errAuthorizationInternalizeNotAllowed:
                self = .internalizeNotAllowed
            case errAuthorizationInvalidFlags:
                self = .invalidFlags
            case errAuthorizationToolExecuteFailure:
                self = .toolExecuteFailure
            case errAuthorizationToolEnvironmentError:
                self = .toolEnvironmentError
            case errAuthorizationBadAddress:
                self = .badAddress
            default:
                self = .internal
        }
    }
    
    var description: String {
        switch self {
            case .invalidSet:
                return "The authorization rights are invalid."
            case .invalidRef:
                return "The authorization reference is invalid."
            case .invalidTag:
                return "The authorization tag is invalid."
            case .invalidPointer:
                return "The returned authorization is invalid."
            case .denied:
                return "The authorization was denied."
            case .canceled:
                return "The authorization was canceled by the user."
            case .interactionNotAllowed:
                return "The authorization was denied since no user interaction was possible."
            case .internal:
                return "Unable to obtain authorization for this operation."
            case .externalizeNotAllowed:
                return "The authorization is not allowed to be converted to an external format."
            case .internalizeNotAllowed:
                return "The authorization is not allowed to be created from an external format."
            case .invalidFlags:
                return "The provided option flag(s) are invalid for this authorization operation."
            case .toolExecuteFailure:
                return "The specified program could not be executed."
            case .toolEnvironmentError:
                return "An invalid status was returned during execution of a privileged tool."
            case .badAddress:
                return "The requested socket address is invalid (must be 0-1023 inclusive)."
        }
    }
}

#endif
