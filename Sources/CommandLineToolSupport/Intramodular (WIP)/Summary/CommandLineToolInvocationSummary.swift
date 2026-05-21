//
//  CommandLineToolInvocationSummary.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Runtime
import Swallow

/// Namespace for the provisional invocation-summary DSL used to intentionally render command arguments.
public enum CommandLineToolInvocationSummary {

}

extension CommandLineToolInvocationSummary {
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// A summary node that can lower part of a command model into rendered invocation arguments.
public protocol InvocationSummary<Command> {
    associatedtype Command: AnyCommandLineTool
    typealias Context = InvocationSummaryContext

    func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: Context
    ) throws -> CommandLineToolInvocation.Arguments
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Type eraser used when switch/case summary branches produce different concrete summary node types.
public struct AnyInvocationSummary<Command: AnyCommandLineTool>: InvocationSummary {
    let base: any InvocationSummary<Command>

    public init(erasing summary: some InvocationSummary<Command>) {
        self.base = summary
    }

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: Context
    ) throws -> CommandLineToolInvocation.Arguments {
        try base.makeInvocationArguments(command: command, parent: parent, context: context)
    }
}

// MARK: - Tuple Invocation Summary

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Tuple-backed summary node produced by result builders when a summary contains multiple child nodes.
public struct TupleInvocationSummary<Command: AnyCommandLineTool, T>: InvocationSummary {
    public var value: T

    @inlinable public init(_ value: T) {
        self.value = value
    }

    private var summaries: [any InvocationSummary<Command>] {
        let metadata = TypeMetadata.Tuple(T.self)
        guard let metadata else { return [] }

        var summaries: [any InvocationSummary<Command>] = []
        for (index, field) in metadata.fields.enumerated() {
            guard let elementType = field.type.base as? any InvocationSummary<Command>.Type else {
                preconditionFailure("element type \(field.type.base) at index \(index) doesn't conform to InvocationSummary.")
                continue
            }
            let summary = withUnsafeBytes(of: value) { buffer in
                func load<Summary: InvocationSummary>(_: Summary.Type) -> Summary {
                    buffer.baseAddress!
                        .advanced(by: field.offset)
                        .load(as: Summary.self)
                }

                return load(elementType)
            }
            summaries.append(summary)
        }
        return summaries
    }

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        try summaries.reduce(into: CommandLineToolInvocation.Arguments()) { result, summary in
            try result.append(
                contentsOf: summary.makeInvocationArguments(
                    command: command,
                    parent: parent,
                    context: context
                )
            )
        }
    }
}

}
