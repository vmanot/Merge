//
// Copyright (c) Vatsal Manot
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemShell {
    package var runningProcesses: [_AsyncProcess] {
        get async {
            await _internalState.runningProcesses
        }
    }

    package var completedRunResults: [Process.RunResult] {
        get async {
            await _internalState.completedRunResults
        }
    }

    package func teardownRunningProcesses() async throws {
        _ = try await teardownRunningProcessesReporting()
    }

    package func _run(
        _ process: _AsyncProcess
    ) async throws -> Process.RunResult {
        await _internalState.insertRunningProcess(process)

        do {
            let result = try await process.run()

            await _internalState.appendCompletedRunResult(result)
            await _internalState.removeRunningProcess(process)

            return result
        } catch {
            await _internalState.removeRunningProcess(process)

            throw error
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemShell {
    package actor _InternalState {
        package private(set) var runningProcesses: [_AsyncProcess] = []
        package private(set) var completedRunResults: [Process.RunResult] = []

        package init() {

        }

        package func insertRunningProcess(
            _ process: _AsyncProcess
        ) {
            guard !runningProcesses.contains(where: { $0 === process }) else {
                return
            }

            runningProcesses.append(process)
        }

        package func removeRunningProcess(
            _ process: _AsyncProcess
        ) {
            runningProcesses.removeAll(where: { $0 === process })
        }

        package func appendCompletedRunResult(
            _ result: Process.RunResult
        ) {
            completedRunResults.append(result)
        }
    }

    package struct OwnershipError: Swift.Error, Hashable, CustomStringConvertible {
        package let reason: String

        package var description: String {
            reason
        }
    }
}
