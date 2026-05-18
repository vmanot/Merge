#if os(macOS)
//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Foundation
import Merge
import Runtime

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

    /// The name of the command-line tool or information being used.
    ///
    /// By default, the lowercased version of the type name would be used if you don't override it.
    ///
    /// Ideally, it should only contain one argument without whitespaces, for example:
    /// - `xcrun` / `swiftc` / `simctl` / etc.
    /// - `git` / `commit` / `push`, etc.
    open var _commandName: String {
        "\(Self.self)".lowercased()
    }

    open var keyConversion: _CommandLineToolOptionKeyConversion? {
        nil
    }

    public init() {

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
                environmentVariables: .inherited(
                    overriding: environmentVariables.mapValues({ String(describing: $0) })
                ),
                currentDirectoryURL: currentDirectoryURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
                standardStreamMirroring: .terminal
            ),
            internalState: shellState,
            ownership: .borrowedFromCommandLineTool,
            borrowedLease: lease,
            shellScopeID: shellScope.id
        )

        do {
            let result: R = try await operation(shell)

            lease.invalidate()
            await shellState._completeShellScope(id: shellScope.id)
            await _internalState._completeShellSession(id: shellScope.id)

            return result
        } catch {
            lease.invalidate()
            await shellState._completeShellScope(id: shellScope.id)
            await _internalState._completeShellSession(id: shellScope.id)

            throw error
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AnyCommandLineTool {
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

#endif
