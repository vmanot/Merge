#if os(macOS)
//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Merge
import Swallow

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AnyCommandLineTool {
    package actor _InternalState: ObjectDidChangeObservableObject {
        nonisolated package let objectWillChange = ObservableObjectPublisher()
        nonisolated package let objectDidChange = _ObjectDidChangePublisher()

        package private(set) var _lifecycleStatus: _LifecycleStatus = .active
        package private(set) var _shellSessions: IdentifierIndexingArrayOf<_ShellSession> = []
        package private(set) var _shellScopes: IdentifierIndexingArrayOf<SystemShell._ShellScope> = []

        package init() {

        }

        package var _activeShellScopes: [SystemShell._ShellScope] {
            _shellScopes.filter { $0.status == .active }
        }

        package var _activeShellSessions: [AnyCommandLineTool._ShellSession] {
            _shellSessions.filter { $0.scope.status == .active }
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

        package func _insertShellSession(
            _ session: AnyCommandLineTool._ShellSession
        ) {
            objectWillChange.send()
            _shellSessions.updateOrAppend(session)
            _shellScopes.updateOrAppend(session.scope)
            objectDidChange.send()
        }

        package func _insertShellSessionAfterValidatingUse(
            _ session: AnyCommandLineTool._ShellSession
        ) throws {
            try _validateCanUse()
            _insertShellSession(session)
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

            if var session = _shellSessions[id: id] {
                session.scope = scope
                _shellSessions[id: id] = session
            }

            objectDidChange.send()
        }

        package func _completeShellSession(
            id: SystemShell._ShellScope.ID
        ) {
            _completeShellScope(id: id)
        }

        package func _beginKill() -> [AnyCommandLineTool._ShellSession] {
            let activeShellSessions = _activeShellSessions

            if _lifecycleStatus != .killed {
                objectWillChange.send()
                _lifecycleStatus = .killed
                objectDidChange.send()
            }

            return activeShellSessions
        }

        package func _validateCanUse() throws {
            guard _lifecycleStatus != .killed else {
                let error = _DeveloperError.killedInstanceUsage

                runtimeIssue(error)
                throw error
            }
        }
    }
}
#endif
