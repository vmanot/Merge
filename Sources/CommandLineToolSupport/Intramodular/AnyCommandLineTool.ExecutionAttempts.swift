//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AnyCommandLineTool {
    package struct _ExecutionAttempt: Identifiable, @unchecked Sendable {
        package typealias ID = UUID

        package let id: ID
        package let startedAt: Date
        package let finishedAt: Date
        package let shellScopeID: SystemShell._ShellScope.ID?
        package let source: _CommandLineToolExecutionSource
        package let result: Result<_CommandLineToolExecutionRecord<AnyCommandLineTool>, Error>

        package init(
            id: ID = ID(),
            startedAt: Date,
            finishedAt: Date,
            shellScopeID: SystemShell._ShellScope.ID?,
            source: _CommandLineToolExecutionSource,
            result: Result<_CommandLineToolExecutionRecord<AnyCommandLineTool>, Error>
        ) {
            self.id = id
            self.startedAt = startedAt
            self.finishedAt = finishedAt
            self.shellScopeID = shellScopeID
            self.source = source
            self.result = result
        }
    }
}
