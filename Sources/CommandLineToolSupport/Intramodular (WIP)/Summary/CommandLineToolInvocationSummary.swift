//
// Copyright (c) Vatsal Manot
//

import Foundation
import Runtime
import Swallow

/// Namespace for the provisional invocation-summary DSL used to intentionally render command arguments.
public enum CommandLineToolInvocationSummary {

}

extension CommandLineToolInvocationSummary {
/// Structured errors produced while evaluating invocation-summary policy.
public enum Error: Swift.Error, CustomStringConvertible {
    case missingExpectedParent(
        command: Any.Type,
        expectedParent: Any.Type,
        actualParent: Any.Type?,
        location: SourceCodeLocation?
    )
    case unsupportedArgument(
        command: CommandLineTool.Name?,
        argument: _ResolvedCommandLineToolDescription.ArgumentID,
        disposition: InvocationSummaryContext.Disposition,
        components: [CommandLineToolInvocation.Component],
        reason: String?,
        location: SourceCodeLocation?
    )
    case conflictingArgumentDisposition(
        command: CommandLineTool.Name?,
        argument: _ResolvedCommandLineToolDescription.ArgumentID,
        existing: InvocationSummaryContext.DispositionRecord,
        new: InvocationSummaryContext.DispositionRecord,
        location: SourceCodeLocation?
    )
    case noSwitchCaseMatched(
        command: CommandLineTool.Name?,
        argument: _ResolvedCommandLineToolDescription.ArgumentID?,
        valueDescription: String,
        location: SourceCodeLocation?
    )
    case conflictingInvocationModes(
        command: CommandLineTool.Name?,
        first: String,
        second: String,
        location: SourceCodeLocation?
    )
    case unsupportedInvocationSummaryModifierContent(
        modifier: String,
        content: Any.Type,
        location: SourceCodeLocation?
    )

    public var description: String {
        switch self {
            case .missingExpectedParent(let command, let expectedParent, let actualParent, let location):
                let actualParentDescription = actualParent.map { String(reflecting: $0) } ?? "nil"

                return "Missing expected parent command while evaluating invocation summary for \(String(reflecting: command)); expected \(String(reflecting: expectedParent)), got \(actualParentDescription)\(location.map { " at \($0)" } ?? "")."
            case .unsupportedArgument(let command, let argument, let disposition, let components, let reason, let location):
                let rendered = components.flatMap(\.rawValues).joined(separator: " ")

                return "Unsupported command-line argument \(argument) for \(command?.rawValue ?? "<unknown>") with disposition \(disposition)\(rendered.isEmpty ? "" : " rendering \(String(reflecting: rendered))")\(reason.map { ": \($0)" } ?? "")\(location.map { " at \($0)" } ?? "")."
            case .conflictingArgumentDisposition(let command, let argument, let existing, let new, let location):
                return "Conflicting invocation-summary disposition for command-line argument \(argument) on \(command?.rawValue ?? "<unknown>"): existing \(existing.disposition), new \(new.disposition)\(location.map { " at \($0)" } ?? "")."
            case .noSwitchCaseMatched(let command, let argument, let valueDescription, let location):
                return "No invocation-summary switch case matched \(argument.map { "\($0) " } ?? "")for \(command?.rawValue ?? "<unknown>") with value \(valueDescription)\(location.map { " at \($0)" } ?? "")."
            case .conflictingInvocationModes(let command, let first, let second, let location):
                return "Conflicting invocation modes for \(command?.rawValue ?? "<unknown>"): \(first) and \(second) both matched\(location.map { " at \($0)" } ?? "")."
            case .unsupportedInvocationSummaryModifierContent(let modifier, let content, let location):
                return "Invocation-summary modifier \(modifier) cannot be applied to content \(String(reflecting: content))\(location.map { " at \($0)" } ?? "")."
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// A summary node that can lower part of a command model into rendered invocation arguments.
public protocol InvocationSummary<Command> {
    associatedtype Command: AnyCommandLineTool
    typealias Context = InvocationSummaryContext

    func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: Context
    ) throws -> [CommandLineToolInvocation.Component]
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

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: Context
    ) throws -> [CommandLineToolInvocation.Component] {
        try base.makeInvocationComponents(command: command, parent: parent, context: context)
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

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        try summaries.reduce(into: [CommandLineToolInvocation.Component]()) { result, summary in
            try result.append(
                contentsOf: summary.makeInvocationComponents(
                    command: command,
                    parent: parent,
                    context: context
                )
            )
        }
    }
}

}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolInvocationSummary.TupleInvocationSummary: CommandLineToolInvocationSummary._InvocationSummaryApplicabilityTarget {
    public func _registerArgumentApplicability(
        command: Command,
        parent: AnyCommandLineTool?,
        context: Context,
        otherwise: _CommandLineToolArgumentApplicability<Command>.Otherwise,
        location: SourceCodeLocation?
    ) throws {
        for summary in summaries {
            guard let target = summary as? any CommandLineToolInvocationSummary._InvocationSummaryApplicabilityTarget<Command> else {
                throw CommandLineToolInvocationSummary.Error.unsupportedInvocationSummaryModifierContent(
                    modifier: String(reflecting: _CommandLineToolArgumentApplicability<Command>.self),
                    content: Swift.type(of: summary),
                    location: location
                )
            }

            try target._registerArgumentApplicability(
                command: command,
                parent: parent,
                context: context,
                otherwise: otherwise,
                location: location
            )
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolInvocationSummary.InvocationSummary {
    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: Context
    ) throws -> CommandLineToolInvocation.Arguments {
        CommandLineToolInvocation.Arguments(
            try makeInvocationComponents(
                command: command,
                parent: parent,
                context: context
            )
            .flatMap(\.argumentValues)
        )
    }
}
