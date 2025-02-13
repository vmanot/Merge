//
// Copyright (c) Vatsal Manot
//

@_exported import class Merge.SystemShell
import Foundation

#if os(macOS)
extension Process {
    @available(*, deprecated)
    public typealias ShellEnvironment = PreferredUNIXShell.Name
}
#endif
