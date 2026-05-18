#if os(macOS)
//
// Copyright (c) Vatsal Manot
//

import Merge

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AnyCommandLineTool {
    package struct _ShellSession: Identifiable, Sendable {
        package typealias ID = SystemShell._ShellScope.ID

        package let id: ID
        package var scope: SystemShell._ShellScope
        package let shellState: SystemShell._InternalState

        package init(
            scope: SystemShell._ShellScope,
            shellState: SystemShell._InternalState
        ) {
            self.id = scope.id
            self.scope = scope
            self.shellState = shellState
        }
    }
}
#endif
