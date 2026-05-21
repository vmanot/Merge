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
extension AnyCommandLineTool {
    @discardableResult
    public func _run(
        command commandLine: String,
        input: String? = nil,
        standardStreamWiring: _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring? = nil,
        applying differences: [SystemShell.Configuration.Difference] = []
    ) async throws -> _CommandLineToolExecutionRecord<AnyCommandLineTool> {
        try await _executionPlan(
            command: commandLine,
            input: input,
            standardStreamWiring: standardStreamWiring,
            applying: differences
        )
        ._run()
    }

    @_disfavoredOverload
    @discardableResult
    public func _run(
        command commandLine: String,
        input: String? = nil,
        standardStreamWiring: _CommandLineToolExecutionPlan<AnyCommandLineTool>.StandardStreamWiring? = nil,
        applying differences: SystemShell.Configuration.Difference...
    ) async throws -> _CommandLineToolExecutionRecord<AnyCommandLineTool> {
        try await _run(
            command: commandLine,
            input: input,
            standardStreamWiring: standardStreamWiring,
            applying: differences
        )
    }
}

