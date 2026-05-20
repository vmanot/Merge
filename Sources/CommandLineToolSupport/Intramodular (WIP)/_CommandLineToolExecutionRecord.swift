//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Merge

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Provisional typed carrier that preserves the modeled tool alongside the raw process result.
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
}

extension _CommandLineToolExecutionRecord {
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

#endif
