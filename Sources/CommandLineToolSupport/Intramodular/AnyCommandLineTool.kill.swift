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
    public func kill() async throws {
        let sessions = await _internalState._beginKill()

        var failedSessionCount = 0

        for session in sessions {
            let report = await session.shellState._teardownRunningProcessesReportingForOwningCommandLineTool()

            if !report.fullySucceeded {
                failedSessionCount += 1
            }

            await session.shellState._completeShellScope(id: session.id)
            await _internalState._completeShellSession(id: session.id)
        }

        guard failedSessionCount == 0 else {
            throw _DeveloperError.failedToKillShellSessions(
                failedSessionCount: failedSessionCount,
                totalSessionCount: sessions.count
            )
        }
    }
}
