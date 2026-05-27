//
// Copyright (c) Vatsal Manot
//

import Combine
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
    package var _commandNameOverrideStorage: CommandLineToolName? = nil

    public var objectWillChange: AnyPublisher<Void, Never> {
        _internalState.objectWillChange.eraseToAnyPublisher()
    }

    public var objectDidChange: AnyPublisher<Void, Never> {
        _internalState.objectDidChange.eraseToAnyPublisher()
    }

    /// The semantic command-line tool name represented as a single invocation argument, when the tool has one.
    open var commandName: CommandLineToolName? {
        _commandNameOverrideStorage
    }

    open var keyConversion: _CommandLineToolOptionKeyConversion? {
        nil
    }

    public init() {

    }

    package var _attachedOutputFormatterToolStorage: (any CommandLineToolOutputFormatterTool)? = nil
    package var _attachedHostToolStorage: _AttachedToolHost? = nil
    package var _attachedStandardStreamWiringStorage: _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring? = nil

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
            _detachTransientExecutionAttachments()
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

    public func withUnsafeSystemShell<R>(
        sink: _ProcessStandardOutputSink,
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        try await withUnsafeSystemShell { shell in
            try await shell.withConfiguration(
                applying: .standardStreamMirroring(
                    SystemShell.StandardStreamMirroring(processStandardOutputSink: sink)
                ),
                perform: operation
            )
        }
    }
}
