//
// Copyright (c) Vatsal Manot
//

#if canImport(Darwin)
import Darwin

/// The exit status of a subprocess.
public enum TerminationStatus: Sendable, Hashable {
    /// The type of the status code.
    public typealias Code = CInt

    /// The subprocess exited with the given code.
    case exited(Code)

    /// The subprocess terminated due to the given signal.
    case signaled(Code)

    /// A Boolean value that indicates whether the termination was successful.
    public var isSuccess: Bool {
        switch self {
            case .exited(let exitCode):
                return exitCode == 0
            case .signaled:
                return false
        }
    }
}

extension TerminationStatus: CustomStringConvertible, CustomDebugStringConvertible {
    /// A textual representation of this termination status.
    public var description: String {
        switch self {
            case .exited(let code):
                return "exited(\(code))"
            case .signaled(let code):
                return "signaled(\(code))"
        }
    }

    /// A debug-oriented textual representation of this termination status.
    public var debugDescription: String {
        self.description
    }
}
#endif
