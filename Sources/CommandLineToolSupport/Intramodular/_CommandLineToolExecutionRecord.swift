#if os(macOS)
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
public struct _CommandLineToolExecutionRecord<Tool: AnyCommandLineTool> {
    public let tool: Tool
    public let source: _CommandLineToolExecutionSource
    public let processResult: Process.RunResult

    public init(
        tool: Tool,
        source: _CommandLineToolExecutionSource,
        processResult: Process.RunResult
    ) {
        self.tool = tool
        self.source = source
        self.processResult = processResult
    }
}

public typealias _CommandLineToolRunResult<Command: CommandLineTool> = _CommandLineToolExecutionRecord<Command>

public enum _CommandLineToolExecutionSource: Hashable, Sendable {
    case modeledInvocation(CommandLineToolInvocation)
    case shellCommandLine(String)
}

extension _CommandLineToolExecutionSource {
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

extension _CommandLineToolExecutionRecord {
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
