//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Foundation
import Merge

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
open class AnyCommandLineTool: Logging, ObjectDidChangeObservableObject {
    public lazy var logger = PassthroughLogger(source: self)
    package let _internalState = _InternalState()

    public var objectWillChange: AnyPublisher<Void, Never> {
        _internalState.objectWillChange.eraseToAnyPublisher()
    }

    public var objectDidChange: AnyPublisher<Void, Never> {
        _internalState.objectDidChange.eraseToAnyPublisher()
    }

    /// The semantic command-line tool name represented as a single invocation argument, when the tool has one.
    open var commandName: CommandLineToolName? {
        nil
    }

    open var keyConversion: _CommandLineToolOptionKeyConversion? {
        nil
    }

    public init() {

    }

    // MARK: Legacy Output Formatter Attachment

    private var __attachedOutputFormatterTool: (any CommandLineToolOutputFormatterTool)? = nil
    private var __attachedHostTool: _AttachedToolHost? = nil
    private var __attachedStandardStreamWiring: _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring? = nil

    public var _attachedOutputFormatterTool: (any CommandLineToolOutputFormatterTool)? {
        get {
            __attachedOutputFormatterTool
        } set {
            guard newValue == nil || __attachedOutputFormatterTool == nil else {
                let error = _DeveloperError.outputFormatterToolAlreadyAttached

                runtimeIssue(error)
                preconditionFailure(error.description)
            }

            __attachedOutputFormatterTool = newValue
        }
    }

    public var _attachedHostTool: _AttachedToolHost? {
        get {
            __attachedHostTool
        } set {
            guard newValue == nil || __attachedHostTool == nil else {
                let error = _DeveloperError.hostToolAlreadyAttached

                runtimeIssue(error)
                preconditionFailure(error.description)
            }

            __attachedHostTool = newValue
        }
    }

    public var _attachedStandardStreamWiring: _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring? {
        get {
            __attachedStandardStreamWiring
        } set {
            __attachedStandardStreamWiring = newValue
        }
    }

    public func _attachOutputFormatterTool(
        _ tool: (any CommandLineToolOutputFormatterTool)?
    ) throws {
        guard tool == nil || __attachedOutputFormatterTool == nil else {
            let error = _DeveloperError.outputFormatterToolAlreadyAttached

            runtimeIssue(error)
            throw error
        }

        __attachedOutputFormatterTool = tool
    }

    public func _attachHostTool(
        _ tool: _AttachedToolHost?
    ) throws {
        guard tool == nil || __attachedHostTool == nil else {
            let error = _DeveloperError.hostToolAlreadyAttached

            runtimeIssue(error)
            throw error
        }

        __attachedHostTool = tool
    }

    public func _detachOutputFormatterTool() {
        __attachedOutputFormatterTool = nil
    }

    public func _detachHostTool() {
        __attachedHostTool = nil
    }

    public func _detachStandardStreamWiring() {
        __attachedStandardStreamWiring = nil
    }

    public var environmentVariables: [String: any CLT.EnvironmentVariableValue] = [:]
    public var currentDirectoryURL: URL? = nil

    @discardableResult
    open func withUnsafeSystemShell<R>(
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        let environmentVariables = _resolveEnvironmentVariables()
        let lease = SystemShell._BorrowedLease()
        let shellState = SystemShell._InternalState()
        let shellScope = SystemShell._ShellScope(kind: .commandLineToolLease)
        let shellSession = _ShellSession(scope: shellScope, shellState: shellState)

        await shellState._insertShellScope(shellScope)
        try await _internalState._insertShellSessionAfterValidatingUse(shellSession)

        let shell = SystemShell(
            configuration: SystemShell.Configuration(
                environmentVariables: .inherited(overriding: environmentVariables.compactMapValues(\.environmentVariableStringValue)),
                currentDirectoryURL: currentDirectoryURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
                standardStreamMirroring: .terminal
            ),
            internalState: shellState,
            ownership: .borrowedFromCommandLineTool,
            borrowedLease: lease,
            shellScopeID: shellScope.id
        )

        defer {
            lease.invalidate()
        }

        let result: Result<R, Error>

        do {
            result = .success(try await operation(shell))
        } catch {
            result = .failure(error)
        }

        await shellState._completeShellScope(id: shellScope.id)
        await _internalState._completeShellSession(id: shellScope.id)

        switch result {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
        }
    }
}

// MARK: - Auxiliary

extension AnyCommandLineTool {
    /// Resolves the full list of environment variables by combining manually set environment variables with runtime-reflected variables that are defined via the `@EnvironmentVariable` property wrapper.
    private func _resolveEnvironmentVariables() -> [String: any CLT.EnvironmentVariableValue] {
        var result: [String: any CLT.EnvironmentVariableValue] = environmentVariables

        let mirror = Mirror(reflecting: self)

        for child in mirror.children {
            guard let propertyWrapper = child.value as? (any _CommandLineToolEnvironmentVariableProtocol) else {
                continue
            }

            let environmentVariableName = propertyWrapper.name
            let environmentVariableValue: any CLT.EnvironmentVariableValue = propertyWrapper.wrappedValue

            if environmentVariables.contains(key: environmentVariableName) {
                fatalError("conflict for \(environmentVariableName)")
            }

            result[environmentVariableName] = environmentVariableValue
        }

        return result
    }

}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AnyCommandLineTool {
    /// Internal command-level execution history item used by runtime diagnostics and future tracing.
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

    package actor _InternalState: ObjectDidChangeObservableObject {
        nonisolated package let objectWillChange = ObservableObjectPublisher()
        nonisolated package let objectDidChange = _ObjectDidChangePublisher()

        package private(set) var _lifecycleStatus: _LifecycleStatus = .active
        package private(set) var _executionAttempts: [AnyCommandLineTool._ExecutionAttempt] = []
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

        package func _appendExecutionAttempt(
            _ attempt: AnyCommandLineTool._ExecutionAttempt
        ) {
            objectWillChange.send()
            _executionAttempts.append(attempt)
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

