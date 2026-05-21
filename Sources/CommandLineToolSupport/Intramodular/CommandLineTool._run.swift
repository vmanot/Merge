//
// Copyright (c) Vatsal Manot
//


import Foundation
import Merge

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineTool {
    @discardableResult
    public func _run(
        invocation: CommandLineToolInvocation,
        applying differences: [SystemShell.Configuration.Difference] = []
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _executionPlan(
            invocation: invocation,
            applying: differences
        )
        ._run()
    }

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

    @discardableResult
    public func _run(
        applying differences: [SystemShell.Configuration.Difference] = []
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _run(
            invocation: try commandInvocation,
            applying: differences
        )
    }

    @_disfavoredOverload
    @discardableResult
    public func _run(
        applying differences: SystemShell.Configuration.Difference...
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _run(applying: differences)
    }

    public func _invocation(
        appending arguments: CommandLineToolInvocation.Arguments
    ) throws -> CommandLineToolInvocation {
        try commandInvocation.appending(arguments)
    }

    @discardableResult
    public func _run(
        appending arguments: CommandLineToolInvocation.Arguments,
        applying differences: [SystemShell.Configuration.Difference] = []
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _run(
            invocation: try _invocation(appending: arguments),
            applying: differences
        )
    }

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

    @discardableResult
    public func _runCollectingOutput(
        appending arguments: CommandLineToolInvocation.Arguments = [],
        applying differences: [SystemShell.Configuration.Difference] = []
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        let differences = differences + [
            SystemShell.Configuration.Difference._collectingOutput
        ]

        if arguments.isEmpty {
            return try await _run(applying: differences)
        } else {
            return try await _run(
                appending: arguments,
                applying: differences
            )
        }
    }

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

    @discardableResult
    public func _run(
        command commandLine: String,
        input: String? = nil,
        applying differences: [SystemShell.Configuration.Difference] = []
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        let record: _CommandLineToolExecutionRecord<AnyCommandLineTool> = try await (self as AnyCommandLineTool)._run(
            command: commandLine,
            input: input,
            applying: differences
        )

        return _CommandLineToolExecutionRecord(
            tool: self,
            source: record.source,
            processResult: record.processResult,
            selectedToolInvocation: record.selectedToolInvocation
        )
    }

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
}

