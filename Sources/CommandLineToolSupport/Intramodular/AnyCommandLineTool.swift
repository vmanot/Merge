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
    /// Defaults applied to every process started by this tool instance.
    ///
    /// An individual execution may override these values with a
    /// ``SystemShell/Configuration/Difference``.
    public struct ExecutionConfiguration: Sendable {
        public var baseEnvironmentVariables: SystemShell.EnvironmentVariables
        public var environmentVariables: [String: any CLT.EnvironmentVariableValue]
        public var currentDirectoryURL: URL?
        public var standardStreamMirroring: SystemShell.StandardStreamMirroring

        public init(
            baseEnvironmentVariables: SystemShell.EnvironmentVariables = .inherited,
            environmentVariables: [String: any CLT.EnvironmentVariableValue] = [:],
            currentDirectoryURL: URL? = nil,
            standardStreamMirroring: SystemShell.StandardStreamMirroring = .terminal
        ) {
            self.baseEnvironmentVariables = baseEnvironmentVariables
            self.environmentVariables = environmentVariables
            self.currentDirectoryURL = currentDirectoryURL
            self.standardStreamMirroring = standardStreamMirroring
        }
    }

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

    public var executionConfiguration = ExecutionConfiguration()

    public init() {
    }

    public convenience init(executionConfiguration: ExecutionConfiguration) {
        self.init()
        self.executionConfiguration = executionConfiguration
    }

    package var _attachedOutputFormatterToolStorage: (any CommandLineToolOutputFormatterTool)? = nil
    package var _attachedHostToolStorage: _AttachedToolHost? = nil
    package var _attachedStandardStreamWiringStorage: _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring? = nil

    public var environmentVariables: [String: any CLT.EnvironmentVariableValue] {
        get { executionConfiguration.environmentVariables }
        set { executionConfiguration.environmentVariables = newValue }
    }

    /// The environment inherited or replaced before modeled and explicitly
    /// configured tool variables are applied.
    public var baseEnvironmentVariables: SystemShell.EnvironmentVariables {
        get { executionConfiguration.baseEnvironmentVariables }
        set { executionConfiguration.baseEnvironmentVariables = newValue }
    }

    public var currentDirectoryURL: URL? {
        get { executionConfiguration.currentDirectoryURL }
        set { executionConfiguration.currentDirectoryURL = newValue }
    }

    /// The standard streams forwarded by executions that do not specify their own policy.
    public var standardStreamMirroring: SystemShell.StandardStreamMirroring {
        get { executionConfiguration.standardStreamMirroring }
        set { executionConfiguration.standardStreamMirroring = newValue }
    }

    @discardableResult
    open func withSystemShell<R>(
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
                environmentVariables: baseEnvironmentVariables.merging(
                    environmentVariables.compactMapValues(\.environmentVariableStringValue),
                    uniquingKeysWith: { _, configuredValue in configuredValue }
                ),
                currentDirectoryURL: currentDirectoryURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
                standardStreamMirroring: standardStreamMirroring
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

    @available(*, deprecated, renamed: "withSystemShell(perform:)")
    @discardableResult
    public func withUnsafeSystemShell<R>(
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        try await withSystemShell(perform: operation)
    }

    public func withSystemShell<R>(
        sink: _ProcessStandardOutputSink,
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        try await withSystemShell { shell in
            try await shell.withConfiguration(
                applying: .standardStreamMirroring(
                    SystemShell.StandardStreamMirroring(processStandardOutputSink: sink)
                ),
                perform: operation
            )
        }
    }

    @available(*, deprecated, renamed: "withSystemShell(sink:perform:)")
    public func withUnsafeSystemShell<R>(
        sink: _ProcessStandardOutputSink,
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        try await withSystemShell(sink: sink, perform: operation)
    }
}
