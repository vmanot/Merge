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
    public func _runCollectingOutput(
        appending arguments: CommandLineToolInvocation.Arguments = [],
        applying differences: [SystemShell.Configuration.Difference] = []
    ) async throws -> _CommandLineToolExecutionRecord<Self> {
        try await _run(
            appending: arguments,
            applying: differences + [._collectingOutput]
        )
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
}
