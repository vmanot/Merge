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
public enum _CommandLineToolExecutionSource: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
    case modeledInvocation(CommandLineToolInvocation)
    case shellCommandLine(String)

    public var description: String {
        commandLine
    }

    public var debugDescription: String {
        switch self {
            case .modeledInvocation(let invocation):
                "_CommandLineToolExecutionSource.modeledInvocation(\(invocation.debugDescription))"
            case .shellCommandLine(let commandLine):
                "_CommandLineToolExecutionSource.shellCommandLine(\(String(reflecting: commandLine)))"
        }
    }

    public var customMirror: Mirror {
        switch self {
            case .modeledInvocation(let invocation):
                Mirror(
                    self,
                    children: [
                        "case": "modeledInvocation",
                        "invocation": invocation,
                        "commandLine": commandLine
                    ],
                    displayStyle: .enum
                )
            case .shellCommandLine(let commandLine):
                Mirror(
                    self,
                    children: [
                        "case": "shellCommandLine",
                        "commandLine": commandLine
                    ],
                    displayStyle: .enum
                )
        }
    }

    public var commandLine: String {
        switch self {
            case .modeledInvocation(let invocation):
                invocation.commandLine
            case .shellCommandLine(let commandLine):
                commandLine
        }
    }

    public var invocation: CommandLineToolInvocation? {
        switch self {
            case .modeledInvocation(let invocation):
                invocation
            case .shellCommandLine:
                nil
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct _CommandLineToolExecutionRecord<Tool: AnyCommandLineTool>: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public let tool: Tool
    public let source: _CommandLineToolExecutionSource
    public let processResult: Process.RunResult
    public let selectedToolInvocation: _CommandLineToolSelectedToolInvocation?

    public init(
        tool: Tool,
        source: _CommandLineToolExecutionSource,
        processResult: Process.RunResult,
        selectedToolInvocation: _CommandLineToolSelectedToolInvocation? = nil
    ) {
        self.tool = tool
        self.source = source
        self.processResult = processResult
        self.selectedToolInvocation = selectedToolInvocation
    }

    public var description: String {
        commandLine
    }

    public var debugDescription: String {
        "_CommandLineToolExecutionRecord(tool: \(String(reflecting: Tool.self)), commandLine: \(String(reflecting: commandLine)), selectedToolInvocation: \(selectedToolInvocation.debugDescription))"
    }

    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "tool": tool,
                "source": source,
                "processResult": processResult,
                "selectedToolInvocation": selectedToolInvocation as Any,
                "commandLine": commandLine
            ],
            displayStyle: .struct
        )
    }

    public var commandLine: String {
        source.commandLine
    }

    public var invocation: CommandLineToolInvocation? {
        source.invocation
    }

    public var stdout: Data? {
        processResult.stdout
    }

    public var stderr: Data? {
        processResult.stderr
    }

    public var stdoutString: String? {
        processResult.stdoutString
    }

    public var stderrString: String? {
        processResult.stderrString
    }

    public var terminationError: ProcessTerminationError? {
        processResult.terminationError
    }

    public var isSelectedToolInvocation: Bool {
        selectedToolInvocation != nil
    }

    public func validate() throws {
        try processResult.validate()
    }

    public func toString() throws -> String {
        try processResult.toString()
    }

    public func decode<T: Decodable>(
        _ type: T.Type,
        using decoder: JSONDecoder = .init()
    ) throws -> T {
        try processResult.decode(type, using: decoder)
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Provisional pre-execution carrier for a modeled or raw command-line tool execution.
public struct _CommandLineToolExecutionPlan<Tool: AnyCommandLineTool>: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public let tool: Tool
    public let source: _CommandLineToolExecutionSource
    public let standardInput: String?
    public let configurationDifferences: [SystemShell.Configuration.Difference]
    public let selectedToolInvocation: _CommandLineToolSelectedToolInvocation?
    public let standardStreamWiring: StandardStreamWiring?

    public init(
        tool: Tool,
        source: _CommandLineToolExecutionSource,
        standardInput: String? = nil,
        configurationDifferences: [SystemShell.Configuration.Difference] = [],
        selectedToolInvocation: _CommandLineToolSelectedToolInvocation? = nil,
        standardStreamWiring: StandardStreamWiring? = nil
    ) {
        self.tool = tool
        self.source = source
        self.standardInput = standardInput
        self.configurationDifferences = configurationDifferences
        self.selectedToolInvocation = selectedToolInvocation
        self.standardStreamWiring = standardStreamWiring
    }

    public var commandLine: String {
        source.commandLine
    }

    public var invocation: CommandLineToolInvocation? {
        source.invocation
    }

    public var description: String {
        commandLine
    }

    public var debugDescription: String {
        "_CommandLineToolExecutionPlan(tool: \(String(reflecting: Tool.self)), commandLine: \(String(reflecting: commandLine)), selectedToolInvocation: \(selectedToolInvocation.debugDescription))"
    }

    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "tool": tool,
                "source": source,
                "standardInput": standardInput as Any,
                "configurationDifferences": configurationDifferences,
                "selectedToolInvocation": selectedToolInvocation as Any,
                "standardStreamWiring": standardStreamWiring as Any,
                "commandLine": commandLine
            ],
            displayStyle: .struct
        )
    }
}

extension _CommandLineToolExecutionPlan {
    @discardableResult
    public func _run() async throws -> _CommandLineToolExecutionRecord<Tool> {
        try await tool.withUnsafeSystemShell { shell in
            try await _run(using: shell)
        }
    }

    @discardableResult
    public func _run(
        using shell: SystemShell
    ) async throws -> _CommandLineToolExecutionRecord<Tool> {
        try standardStreamWiring?.validate()

        let startedAt = Date()

        do {
            let (record, shellScopeID) = try await shell.withConfiguration(applying: configurationDifferences) { shell in
                let processResult: Process.RunResult

                switch source {
                    case .modeledInvocation(let invocation):
                        processResult = try await shell._run(
                            invocation: invocation,
                            prefersDirectExecution: selectedToolInvocation == nil
                        )
                    case .shellCommandLine(let commandLine):
                        processResult = try await shell.run(command: commandLine, input: standardInput)
                }

                return (
                    _CommandLineToolExecutionRecord(
                        tool: tool,
                        source: source,
                        processResult: processResult,
                        selectedToolInvocation: selectedToolInvocation
                    ),
                    shell._shellScopeID
                )
            }

            await tool._internalState._appendExecutionAttempt(
                _makeExecutionAttempt(
                    startedAt: startedAt,
                    finishedAt: Date(),
                    shellScopeID: shellScopeID,
                    result: .success(record._erasingTool())
                )
            )

            return record
        } catch {
            await tool._internalState._appendExecutionAttempt(
                _makeExecutionAttempt(
                    startedAt: startedAt,
                    finishedAt: Date(),
                    shellScopeID: shell._shellScopeID,
                    result: .failure(error)
                )
            )

            throw error
        }
    }

    private func _makeExecutionAttempt(
        startedAt: Date,
        finishedAt: Date,
        shellScopeID: SystemShell._ShellScope.ID?,
        result: Result<_CommandLineToolExecutionRecord<AnyCommandLineTool>, Error>
    ) -> AnyCommandLineTool._ExecutionAttempt {
        AnyCommandLineTool._ExecutionAttempt(
            startedAt: startedAt,
            finishedAt: finishedAt,
            shellScopeID: shellScopeID,
            source: source,
            result: result
        )
    }
}

extension _CommandLineToolExecutionRecord {
    fileprivate func _erasingTool() -> _CommandLineToolExecutionRecord<AnyCommandLineTool> {
        _CommandLineToolExecutionRecord<AnyCommandLineTool>(
            tool: tool,
            source: source,
            processResult: processResult,
            selectedToolInvocation: selectedToolInvocation
        )
    }
}

extension SystemShell {
    fileprivate func _run(
        invocation: CommandLineToolInvocation,
        prefersDirectExecution: Bool = true
    ) async throws -> Process.RunResult {
        if prefersDirectExecution, let executableInvocation = invocation.executableInvocation {
            switch executableInvocation.executable {
                case .name(let name):
                    return try await _runDirectly(
                        executableName: name,
                        arguments: executableInvocation.arguments.rawValues
                    )
                case .fileURL(let url):
                    return try await _runDirectly(
                        executableURL: url,
                        arguments: executableInvocation.arguments.rawValues
                    )
            }
        }

        return try await run(command: invocation.renderedCommandLine(using: .posixShellCommandLine))
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineTool {
    public func _executionPlan(
        invocation: CommandLineToolInvocation,
        standardStreamWiring: _CommandLineToolExecutionPlan<Self>.StandardStreamWiring? = nil,
        applying differences: [SystemShell.Configuration.Difference] = []
    ) -> _CommandLineToolExecutionPlan<Self> {
        _CommandLineToolExecutionPlan(
            tool: self,
            source: .modeledInvocation(invocation),
            configurationDifferences: differences,
            selectedToolInvocation: _selectedToolInvocation(renderedInvocation: invocation),
            standardStreamWiring: standardStreamWiring
        )
    }

    @_disfavoredOverload
    public func _executionPlan(
        invocation: CommandLineToolInvocation,
        standardStreamWiring: _CommandLineToolExecutionPlan<Self>.StandardStreamWiring? = nil,
        applying differences: SystemShell.Configuration.Difference...
    ) -> _CommandLineToolExecutionPlan<Self> {
        _executionPlan(
            invocation: invocation,
            standardStreamWiring: standardStreamWiring,
            applying: differences
        )
    }

    public func _executionPlan(
        standardStreamWiring: _CommandLineToolExecutionPlan<Self>.StandardStreamWiring? = nil,
        applying differences: [SystemShell.Configuration.Difference] = []
    ) throws -> _CommandLineToolExecutionPlan<Self> {
        try _executionPlan(
            invocation: commandInvocation,
            standardStreamWiring: standardStreamWiring,
            applying: differences
        )
    }

    @_disfavoredOverload
    public func _executionPlan(
        standardStreamWiring: _CommandLineToolExecutionPlan<Self>.StandardStreamWiring? = nil,
        applying differences: SystemShell.Configuration.Difference...
    ) throws -> _CommandLineToolExecutionPlan<Self> {
        try _executionPlan(
            standardStreamWiring: standardStreamWiring,
            applying: differences
        )
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AnyCommandLineTool {
    public func _executionPlan(
        command commandLine: String,
        input: String? = nil,
        standardStreamWiring: _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring? = nil,
        applying differences: [SystemShell.Configuration.Difference] = []
    ) -> _CommandLineToolExecutionPlan<AnyCommandLineTool> {
        _CommandLineToolExecutionPlan(
            tool: self,
            source: .shellCommandLine(commandLine),
            standardInput: input,
            configurationDifferences: differences,
            standardStreamWiring: standardStreamWiring ?? _attachedStandardStreamWiring
        )
    }

    @_disfavoredOverload
    public func _executionPlan(
        command commandLine: String,
        input: String? = nil,
        standardStreamWiring: _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring? = nil,
        applying differences: SystemShell.Configuration.Difference...
    ) -> _CommandLineToolExecutionPlan<AnyCommandLineTool> {
        _executionPlan(
            command: commandLine,
            input: input,
            standardStreamWiring: standardStreamWiring,
            applying: differences
        )
    }
}
