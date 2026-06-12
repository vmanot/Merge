//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

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

    package var completedRunResults: [_ProcessRunResult] {
        get async {
            await _internalState.completedRunResults
        }
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    package func teardownRunningProcesses() async throws {
        _ = try await teardownRunningProcessesReporting()
    }

    package func _run(
        _ process: _AsyncProcess
    ) async throws -> _ProcessRunResult {
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
    package actor _InternalState: ObjectDidChangeObservableObject {
        nonisolated package let objectWillChange = ObservableObjectPublisher()
        nonisolated package let objectDidChange = _ObjectDidChangePublisher()

        package private(set) var _shellScopes: IdentifierIndexingArrayOf<SystemShell._ShellScope> = []
        package private(set) var runningProcesses: [_AsyncProcess] = []
        package private(set) var completedRunResults: [_ProcessRunResult] = []

        package init() {

        }

        package var _activeShellScopes: [SystemShell._ShellScope] {
            _shellScopes.filter { $0.status == .active }
        }

        package var _completedShellScopes: [SystemShell._ShellScope] {
            _shellScopes.filter { $0.status == .completed }
        }

        package func _shellScope(
            id: SystemShell._ShellScope.ID
        ) -> SystemShell._ShellScope? {
            _shellScopes[id: id]
        }

        package func _childShellScopes(
            of parentID: SystemShell._ShellScope.ID
        ) -> [SystemShell._ShellScope] {
            _shellScopes.filter { $0.parentID == parentID }
        }

        package func _descendantShellScopes(
            of rootID: SystemShell._ShellScope.ID
        ) -> [SystemShell._ShellScope] {
            _shellScopes.filter { $0.rootID == rootID && $0.id != rootID }
        }

        package func _insertShellScope(
            _ scope: SystemShell._ShellScope
        ) {
            objectWillChange.send()
            _shellScopes.updateOrAppend(scope)
            objectDidChange.send()
        }

        package func _completeShellScope(
            id: SystemShell._ShellScope.ID
        ) {
            guard var scope = _shellScopes[id: id], scope.status != .completed else {
                return
            }

            objectWillChange.send()
            scope.status = .completed
            _shellScopes[id: id] = scope
            objectDidChange.send()
        }

        package func insertRunningProcess(
            _ process: _AsyncProcess
        ) {
            guard !runningProcesses.contains(where: { $0 === process }) else {
                return
            }

            objectWillChange.send()
            runningProcesses.append(process)
            objectDidChange.send()
        }

        package func removeRunningProcess(
            _ process: _AsyncProcess
        ) {
            guard runningProcesses.contains(where: { $0 === process }) else {
                return
            }

            objectWillChange.send()
            runningProcesses.removeAll(where: { $0 === process })
            objectDidChange.send()
        }

        package func appendCompletedRunResult(
            _ result: _ProcessRunResult
        ) {
            objectWillChange.send()
            completedRunResults.append(result)
            objectDidChange.send()
        }
    }

    package struct OwnershipError: Swift.Error, Hashable, CustomStringConvertible {
        package let reason: String

        package var description: String {
            reason
        }
    }
}
