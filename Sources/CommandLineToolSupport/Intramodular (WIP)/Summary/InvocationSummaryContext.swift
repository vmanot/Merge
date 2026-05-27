//
// Copyright (c) Vatsal Manot
//


import Foundation
import OrderedCollections
import Swallow

extension CommandLineToolInvocationSummary {
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Tracks arguments already handled by explicit summary nodes so default rendering can avoid duplicates.
public final class InvocationSummaryContext {
    private var typedValues: [ObjectIdentifier: Any] = [:]
    private(set) var dispositionRecords: OrderedDictionary<_ResolvedCommandLineToolDescription.ArgumentID, DispositionRecord> = [:]
    package private(set) var rewriteRules: [RewriteRule] = []

    public init() {

    }

    public convenience init<Value>(
        value: Value,
        for type: Value.Type = Value.self
    ) {
        self.init()
        setValue(value, for: type)
    }

    public func setValue<Value>(
        _ value: Value,
        for type: Value.Type = Value.self
    ) {
        typedValues[ObjectIdentifier(type)] = value
    }

    public func removeValue<Value>(
        for type: Value.Type = Value.self
    ) {
        typedValues.removeValue(forKey: ObjectIdentifier(type))
    }

    public func value<Value>(
        for type: Value.Type = Value.self
    ) -> Value? {
        typedValues[ObjectIdentifier(type)] as? Value
    }

    public func containsValue<Value>(
        for type: Value.Type = Value.self
    ) -> Bool {
        typedValues[ObjectIdentifier(type)] != nil
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
        public var defaultPosition: _CommandLineToolArgumentPosition?
        public var components: [CommandLineToolInvocation.Component]
        public var reason: String?
        public var location: SourceCodeLocation?

        public init(
            argumentID: _ResolvedCommandLineToolDescription.ArgumentID,
            disposition: Disposition,
            defaultPosition: _CommandLineToolArgumentPosition? = nil,
            components: [CommandLineToolInvocation.Component] = [],
            reason: String? = nil,
            location: SourceCodeLocation? = nil
        ) {
            self.argumentID = argumentID
            self.disposition = disposition
            self.defaultPosition = defaultPosition
            self.components = components
            self.reason = reason
            self.location = location
        }

        public var identifiedComponents: [_ResolvedCommandLineToolDescription.IdentifiedInvocationComponent] {
            components.map {
                _ResolvedCommandLineToolDescription.IdentifiedInvocationComponent(
                    argumentID: argumentID,
                    defaultPosition: defaultPosition,
                    component: $0
                )
            }
        }
    }

    public var argumentDispositionRecords: [DispositionRecord] {
        Array(dispositionRecords.values)
    }

    public func argumentDispositionRecords(
        forPropertyNames propertyNames: Set<String>
    ) -> [DispositionRecord] {
        argumentDispositionRecords.filter {
            propertyNames.contains($0.argumentID.propertyName)
        }
    }

    public func argumentDispositionRecords<Command: AnyCommandLineTool>(
        for keyPaths: [PartialKeyPath<Command>],
        command: Command
    ) -> [DispositionRecord] {
        let argumentIDs = Set(
            keyPaths.map {
                Self.argumentID(command: command, keyPath: $0)
            }
        )

        return argumentDispositionRecords.filter {
            argumentIDs.contains($0.argumentID)
        }
    }

    public func identifiedInvocationComponents<Command: AnyCommandLineTool>(
        for keyPaths: [PartialKeyPath<Command>],
        command: Command
    ) -> [_ResolvedCommandLineToolDescription.IdentifiedInvocationComponent] {
        argumentDispositionRecords(for: keyPaths, command: command)
            .flatMap(\.identifiedComponents)
    }

    public func invocationComponents<Command: AnyCommandLineTool>(
        for keyPaths: [PartialKeyPath<Command>],
        command: Command
    ) -> CommandLineToolInvocation.Components {
        CommandLineToolInvocation.Components(
            identifiedInvocationComponents(for: keyPaths, command: command)
                .map(\.component)
        )
    }

    static func argumentName<Command: AnyCommandLineTool>(
        for keyPath: PartialKeyPath<Command>
    ) -> String {
        String(describing: keyPath).dropPrefixIfPresent("\\\(String(describing: Command.self)).$")
    }

    static func argumentID<Command: AnyCommandLineTool>(
        command: Command,
        keyPath: PartialKeyPath<Command>
    ) -> _ResolvedCommandLineToolDescription.ArgumentID {
        _ResolvedCommandLineToolDescription.ArgumentID(
            rawValue: argumentName(for: keyPath),
            commandName: command.requireCommandName()
        )
    }

    @discardableResult
    func registerHandledValueReference<Command: AnyCommandLineTool, Value: InvocationSummaryValue>(
        command: Command,
        _ keyPath: KeyPath<Command, Value>,
        disposition: Disposition,
        defaultPosition: _CommandLineToolArgumentPosition? = nil,
        components: [CommandLineToolInvocation.Component] = [],
        reason: String? = nil,
        location: SourceCodeLocation? = nil
    ) throws -> Bool {
        try registerDisposition(
            .init(
                argumentID: Self.argumentID(command: command, keyPath: keyPath),
                disposition: disposition,
                defaultPosition: defaultPosition,
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
                commandName: command.requireCommandName()
            )
        ] != nil
    }

    @discardableResult
    func registerHandledArgument<Command: AnyCommandLineTool>(
        command: Command,
        argumentName: String,
        disposition: Disposition,
        defaultPosition: _CommandLineToolArgumentPosition? = nil,
        components: [CommandLineToolInvocation.Component] = [],
        reason: String? = nil,
        location: SourceCodeLocation? = nil
    ) throws -> Bool {
        try registerDisposition(
            .init(
                argumentID: _ResolvedCommandLineToolDescription.ArgumentID(
                    rawValue: argumentName,
                    commandName: command.requireCommandName()
                ),
                disposition: disposition,
                defaultPosition: defaultPosition,
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
        _ rule: RewriteRule
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

    package struct RewriteRule {
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

}
