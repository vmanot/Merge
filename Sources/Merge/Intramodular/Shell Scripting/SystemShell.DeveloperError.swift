//
// Copyright (c) Vatsal Manot
//

extension SystemShell {
    public enum DeveloperError: Swift.Error, Hashable, CustomStringConvertible {
        case borrowedShellMutation(String)
        case conflictingConfigurationDifferences
        case invalidBorrowedShellLease
        case unsupportedStandardStreamMirroring(StandardStreamMirroring)

        public var description: String {
            switch self {
                case .borrowedShellMutation(let property):
                    return "Cannot mutate \(property) on a SystemShell borrowed through AnyCommandLineTool.withUnsafeSystemShell. Use withConfiguration(applying:perform:) to derive a scoped child shell."
                case .conflictingConfigurationDifferences:
                    return "Cannot apply conflicting SystemShell.Configuration.Difference values in the same scope."
                case .invalidBorrowedShellLease:
                    return "Cannot use a SystemShell borrowed through AnyCommandLineTool.withUnsafeSystemShell after the closure has returned."
                case .unsupportedStandardStreamMirroring(let mirroring):
                    return "Unsupported SystemShell.StandardStreamMirroring combination: \(mirroring)."
            }
        }
    }
}
