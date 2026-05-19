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
extension AnyCommandLineTool {
    @discardableResult
    public func _run(
        command commandLine: String,
        input: String? = nil,
        applying differences: [SystemShell.Configuration.Difference] = []
    ) async throws -> _CommandLineToolExecutionRecord<AnyCommandLineTool> {
        try await withUnsafeSystemShell { shell in
            try await shell.withConfiguration(applying: differences) { shell in
                let processResult = try await shell.run(command: commandLine, input: input)

                return _CommandLineToolExecutionRecord(
                    tool: self,
                    source: .shellCommandLine(commandLine),
                    processResult: processResult
                )
            }
        }
    }

    @_disfavoredOverload
    @discardableResult
    public func _run(
        command commandLine: String,
        input: String? = nil,
        applying differences: SystemShell.Configuration.Difference...
    ) async throws -> _CommandLineToolExecutionRecord<AnyCommandLineTool> {
        try await _run(
            command: commandLine,
            input: input,
            applying: differences
        )
    }
}

#endif
