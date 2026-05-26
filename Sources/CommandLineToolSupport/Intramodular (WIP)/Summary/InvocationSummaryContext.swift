//
// Copyright (c) Vatsal Manot
//


import Foundation
import Swallow

extension CommandLineToolInvocationSummary {
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Tracks arguments already handled by explicit summary nodes so default rendering can avoid duplicates.
public final class InvocationSummaryContext {
    private(set) var dispositionRecords: [_ResolvedCommandLineToolDescription.ArgumentID: DispositionRecord] = [:]
    package private(set) var rewriteRules: [InvocationRewriteRule] = []

    public init() {

    }

    public enum Disposition: CustomStringConvertible, Hashable, Sendable {
        case explicitRender
        case defaultRender
        case omitted
        case unavailable

        public var description: String {
            switch self {
                case .explicitRender:
                    "explicitRender"
                case .defaultRender:
                    "defaultRender"
                case .omitted:
                    "omitted"
                case .unavailable:
                    "unavailable"
            }
        }
    }

    public struct DispositionRecord: Hashable, Sendable {
        public var argumentID: _ResolvedCommandLineToolDescription.ArgumentID
        public var disposition: Disposition
        public var components: [CommandLineToolInvocation.Component]
        public var reason: String?
        public var location: SourceCodeLocation?

        public init(
            argumentID: _ResolvedCommandLineToolDescription.ArgumentID,
            disposition: Disposition,
            components: [CommandLineToolInvocation.Component] = [],
            reason: String? = nil,
            location: SourceCodeLocation? = nil
        ) {
            self.argumentID = argumentID
            self.disposition = disposition
            self.components = components
            self.reason = reason
            self.location = location
        }
    }

    static func argumentName<Command: AnyCommandLineTool, Value: InvocationSummaryValue>(
        for keyPath: KeyPath<Command, Value>
    ) -> String {
        String(describing: keyPath).dropPrefixIfPresent("\\\(String(describing: Command.self)).$")
    }

    static func argumentID<Command: AnyCommandLineTool, Value: InvocationSummaryValue>(
        command: Command,
        keyPath: KeyPath<Command, Value>
    ) -> _ResolvedCommandLineToolDescription.ArgumentID {
        _ResolvedCommandLineToolDescription.ArgumentID(
            rawValue: argumentName(for: keyPath),
            commandName: command.requireCommandName().rawValue
        )
    }

    @discardableResult
    func registerHandledValueReference<Command: AnyCommandLineTool, Value: InvocationSummaryValue>(
        command: Command,
        _ keyPath: KeyPath<Command, Value>,
        disposition: Disposition,
        components: [CommandLineToolInvocation.Component] = [],
        reason: String? = nil,
        location: SourceCodeLocation? = nil
    ) throws -> Bool {
        try registerDisposition(
            .init(
                argumentID: Self.argumentID(command: command, keyPath: keyPath),
                disposition: disposition,
                components: components,
                reason: reason,
                location: location
            ),
            command: command
        )
    }

    func argumentIsHandled<Command: AnyCommandLineTool, Value: InvocationSummaryValue>(
        command: Command,
        _ keyPath: KeyPath<Command, Value>
    ) -> Bool {
        dispositionRecords[Self.argumentID(command: command, keyPath: keyPath)] != nil
    }

    func argumentIsHandled<Command: AnyCommandLineTool>(
        command: Command,
        argumentName: String
    ) -> Bool {
        dispositionRecords[
            .init(
                rawValue: argumentName,
                commandName: command.requireCommandName().rawValue
            )
        ] != nil
    }

    @discardableResult
    func registerHandledArgument<Command: AnyCommandLineTool>(
        command: Command,
        argumentName: String,
        disposition: Disposition,
        components: [CommandLineToolInvocation.Component] = [],
        reason: String? = nil,
        location: SourceCodeLocation? = nil
    ) throws -> Bool {
        try registerDisposition(
            .init(
                argumentID: _ResolvedCommandLineToolDescription.ArgumentID(
                    rawValue: argumentName,
                    commandName: command.requireCommandName().rawValue
                ),
                disposition: disposition,
                components: components,
                reason: reason,
                location: location
            ),
            command: command
        )
    }

    @discardableResult
    private func registerDisposition<Command: AnyCommandLineTool>(
        _ record: DispositionRecord,
        command: Command
    ) throws -> Bool {
        if let existing = dispositionRecords[record.argumentID] {
            guard Self.dispositionsAreCompatible(existing, record) else {
                throw CommandLineToolInvocationSummary.Error.conflictingArgumentDisposition(
                    command: command.commandName,
                    argument: record.argumentID,
                    existing: existing,
                    new: record,
                    location: record.location ?? existing.location
                )
            }

            return false
        }

        dispositionRecords[record.argumentID] = record

        return true
    }

    private static func dispositionsAreCompatible(
        _ existing: DispositionRecord,
        _ new: DispositionRecord
    ) -> Bool {
        switch (existing.disposition, new.disposition) {
            case (.explicitRender, .explicitRender),
                 (.defaultRender, .defaultRender),
                 (.omitted, .omitted),
                 (.unavailable, .unavailable),
                 (.explicitRender, .defaultRender),
                 (.defaultRender, .explicitRender),
                 (.omitted, .defaultRender),
                 (.defaultRender, .omitted):
                return true
            case (.unavailable, .defaultRender), (.defaultRender, .unavailable):
                return existing.components.isEmpty && new.components.isEmpty
            default:
                return false
        }
    }

    package func registerRewriteRule(
        _ rule: InvocationRewriteRule
    ) {
        rewriteRules.append(rule)
    }

    package func applyRewriteRules(
        to invocation: inout CommandLineToolInvocation
    ) throws {
        for rule in rewriteRules {
            try rule.apply(to: &invocation)
        }
    }
}

package struct InvocationRewriteRule {
    private let body: (inout CommandLineToolInvocation) throws -> Void

    package init(
        _ body: @escaping (inout CommandLineToolInvocation) throws -> Void
    ) {
        self.body = body
    }

    package func apply(
        to invocation: inout CommandLineToolInvocation
    ) throws {
        try body(&invocation)
    }

    package static func replaceOptionValues(
        named name: String,
        _ transform: @escaping (CommandLineToolInvocation.Arguments) throws -> CommandLineToolInvocation.Arguments
    ) -> Self {
        Self { invocation in
            invocation.components = try invocation.components.map { component in
                guard component.isOption(named: name) else {
                    return component
                }

                return try component.replacingOptionValues(transform(component.values))
            }
        }
    }
}

}
