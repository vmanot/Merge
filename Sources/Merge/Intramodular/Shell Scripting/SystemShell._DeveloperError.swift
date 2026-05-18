//
// Copyright (c) Vatsal Manot
//

extension SystemShell {
    public enum _DeveloperError: Swift.Error, Hashable, CustomStringConvertible {
        case borrowedShellOwnedOperation(_OwnedOperation)
        case borrowedShellMutation(_MutableProperty)
        case conflictingConfigurationDifferences
        case failedToKillRunningCommands(failedProcessCount: Int, totalProcessCount: Int)
        case invalidBorrowedShellLease
        case unsupportedStandardStreamMirroring(StandardStreamMirroring)

        public var description: String {
            switch self {
                case .borrowedShellOwnedOperation(let operation):
                    return "Cannot perform \(operation) on a SystemShell borrowed through AnyCommandLineTool.withUnsafeSystemShell. The caller that creates or owns the shell must perform this operation."
                case .borrowedShellMutation(let property):
                    return "Cannot mutate \(property) on a SystemShell borrowed through AnyCommandLineTool.withUnsafeSystemShell. Use withConfiguration(applying:perform:) to derive a scoped child shell."
                case .conflictingConfigurationDifferences:
                    return "Cannot apply conflicting SystemShell.Configuration.Difference values in the same scope."
                case .failedToKillRunningCommands(let failedProcessCount, let totalProcessCount):
                    return "Failed to kill running commands for SystemShell: \(failedProcessCount) of \(totalProcessCount) tracked command(s) remained incomplete after teardown."
                case .invalidBorrowedShellLease:
                    return "Cannot use a SystemShell borrowed through AnyCommandLineTool.withUnsafeSystemShell after the closure has returned."
                case .unsupportedStandardStreamMirroring(let mirroring):
                    return "Unsupported SystemShell.StandardStreamMirroring combination: \(mirroring)."
            }
        }
    }

    public enum _OwnedOperation: Hashable, Sendable, CustomStringConvertible {
        case kill
        case teardownRunningProcesses

        public var description: String {
            switch self {
                case .kill:
                    return "kill()"
                case .teardownRunningProcesses:
                    return "teardownRunningProcesses"
            }
        }
    }

    public enum _MutableProperty: Hashable, Sendable, CustomStringConvertible {
        case currentDirectoryURL
        case environmentVariables
        case options

        public var description: String {
            switch self {
                case .currentDirectoryURL:
                    return "currentDirectoryURL"
                case .environmentVariables:
                    return "environmentVariables"
                case .options:
                    return "options"
            }
        }
    }
}
