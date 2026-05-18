//
// Copyright (c) Vatsal Manot
//

@testable import Merge

import Combine
import Foundation
import Testing

@Suite("SystemShell shell scope tracking", .serialized)
struct SystemShellShellScopeTests {
    @Test("Stores shell scopes by identifier and derives lifecycle views")
    func storesShellScopesByIdentifierAndDerivesLifecycleViews() async throws {
        let state = SystemShell._InternalState()
        let root = SystemShell._ShellScope(kind: .commandLineToolLease)
        let child = SystemShell._ShellScope(
            parentID: root.id,
            rootID: root.rootID,
            kind: .configurationScope
        )
        let grandchild = SystemShell._ShellScope(
            parentID: child.id,
            rootID: root.rootID,
            kind: .configurationScope
        )

        await state._insertShellScope(root)
        await state._insertShellScope(child)
        await state._insertShellScope(grandchild)
        await state._completeShellScope(id: child.id)

        let storedRoot = await state._shellScope(id: root.id)
        let childScopes = await state._childShellScopes(of: root.id)
        let descendantScopes = await state._descendantShellScopes(of: root.id)
        let activeScopes = await state._activeShellScopes
        let completedScopes = await state._completedShellScopes

        #expect(storedRoot?.id == root.id, "Shell scopes should be lookupable by stable identifier.")
        #expect(childScopes.map(\.id) == [child.id], "Child scope lookup should use direct parent IDs.")
        #expect(
            descendantScopes.map(\.id) == [child.id, grandchild.id],
            "Descendant lookup should preserve insertion order for a root scope."
        )
        #expect(
            activeScopes.map(\.id) == [root.id, grandchild.id],
            "Active scope view should be derived from scope status."
        )
        #expect(
            completedScopes.map(\.id) == [child.id],
            "Completed scope view should be derived from scope status."
        )
    }

    @Test("Publishes changes after shell scope mutation")
    func publishesChangesAfterShellScopeMutation() async throws {
        let state = SystemShell._InternalState()
        let scope = SystemShell._ShellScope(kind: .commandLineToolLease)
        var cancellable: AnyCancellable?

        await withCheckedContinuation { continuation in
            cancellable = state.objectDidChange.prefix(1).sink {
                continuation.resume()
            }

            Task {
                await state._insertShellScope(scope)
            }
        }

        withExtendedLifetime(cancellable) {}
        #expect(await state._shellScope(id: scope.id)?.status == .active)
    }

    @Test("SystemShell publishes internal state changes")
    func systemShellPublishesInternalStateChanges() async throws {
        let shell = SystemShell()
        let scope = SystemShell._ShellScope(kind: .commandLineToolLease)
        var cancellable: AnyCancellable?

        await withCheckedContinuation { continuation in
            cancellable = shell.objectDidChange.prefix(1).sink {
                continuation.resume()
            }

            Task {
                await shell._internalState._insertShellScope(scope)
            }
        }

        withExtendedLifetime(cancellable) {}
        #expect(await shell._internalState._shellScope(id: scope.id)?.status == .active)
    }

    @Test("Tracks configuration child shell scopes")
    func tracksConfigurationChildShellScopes() async throws {
        let state = SystemShell._InternalState()
        let rootScope = SystemShell._ShellScope(kind: .commandLineToolLease)

        await state._insertShellScope(rootScope)

        let shell = SystemShell(
            configuration: SystemShell.Configuration(
                environmentVariables: .inherited(overriding: [:]),
                currentDirectoryURL: nil,
                standardStreamMirroring: .disabled
            ),
            internalState: state,
            ownership: .local,
            borrowedLease: nil,
            shellScopeID: rootScope.id
        )

        try await shell.withConfiguration(
            applying: SystemShell.Configuration.Difference.currentDirectoryURL(nil)
        ) { childShell in
            let childScopeID = try #require(
                childShell._shellScopeID,
                "A scoped child shell should receive a shell scope identifier."
            )
            let childScope = try #require(
                await state._shellScope(id: childScopeID),
                "The child shell scope should be inserted before the scoped operation runs."
            )

            #expect(childScope.parentID == rootScope.id)
            #expect(childScope.rootID == rootScope.id)
            #expect(childScope.kind == .configurationScope)
            #expect(childScope.status == .active)
        }

        let completedChildren = await state._completedShellScopes.filter { $0.parentID == rootScope.id }

        #expect(completedChildren.count == 1, "The child scope should complete after the scoped operation returns.")
        #expect(completedChildren.first?.status == .completed)
    }
}
