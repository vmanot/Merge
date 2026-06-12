//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge
import ShellScripting

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineTool {
    @_disfavoredOverload
    @discardableResult
    public func _run(
        invocation: CommandLineToolInvocation,
        applying differences: SystemShell.Configuration.Difference...
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _run(
            invocation: invocation,
            applying: differences
        )
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @_disfavoredOverload
    @discardableResult
    public func _run(
        applying differences: SystemShell.Configuration.Difference...
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _run(applying: differences)
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @_disfavoredOverload
    @discardableResult
    public func _run(
        appending arguments: [String],
        applying differences: [SystemShell.Configuration.Difference] = []
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _run(
            appending: CommandLineToolInvocation.Arguments(arguments),
            applying: differences
        )
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @_disfavoredOverload
    @discardableResult
    public func _run(
        appending arguments: CommandLineToolInvocation.Arguments,
        applying differences: SystemShell.Configuration.Difference...
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _run(
            appending: arguments,
            applying: differences
        )
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @_disfavoredOverload
    @discardableResult
    public func _run(
        appending arguments: [String],
        applying differences: SystemShell.Configuration.Difference...
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _run(
            appending: CommandLineToolInvocation.Arguments(arguments),
            applying: differences
        )
    }

    @_disfavoredOverload
    @discardableResult
    public func _run(
        command commandString: _ShellCommandString,
        input: String? = nil,
        applying differences: SystemShell.Configuration.Difference...
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _run(
            command: commandString,
            input: input,
            applying: differences
        )
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @_disfavoredOverload
    @discardableResult
    public func _run(
        command commandLine: String,
        input: String? = nil,
        applying differences: SystemShell.Configuration.Difference...
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _run(
            command: commandLine,
            input: input,
            applying: differences
        )
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @_disfavoredOverload
    @discardableResult
    public func _runCollectingOutput(
        appending arguments: [String],
        applying differences: [SystemShell.Configuration.Difference] = []
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _runCollectingOutput(
            appending: CommandLineToolInvocation.Arguments(arguments),
            applying: differences
        )
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @_disfavoredOverload
    @discardableResult
    public func _runCollectingOutput(
        appending arguments: CommandLineToolInvocation.Arguments = [],
        applying differences: SystemShell.Configuration.Difference...
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _runCollectingOutput(
            appending: arguments,
            applying: differences
        )
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    @_disfavoredOverload
    @discardableResult
    public func _runCollectingOutput(
        appending arguments: [String],
        applying differences: SystemShell.Configuration.Difference...
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _runCollectingOutput(
            appending: CommandLineToolInvocation.Arguments(arguments),
            applying: differences
        )
    }
}
