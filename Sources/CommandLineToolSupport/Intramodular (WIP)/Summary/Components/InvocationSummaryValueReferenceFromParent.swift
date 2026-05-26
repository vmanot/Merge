//
// Copyright (c) Vatsal Manot
//


import Foundation
import Swallow

@dynamicMemberLookup
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol _InvocationSummarySubcommandWithParentCommand {
    associatedtype ParentCommand: CommandLineTool
}

extension _InvocationSummarySubcommandWithParentCommand where Self: AnyCommandLineTool {
    public subscript<Value>(
        dynamicMember keyPath: KeyPath<ParentCommand, Value>
    ) -> CommandLineToolInvocationSummary.InvocationSummaryValueReferenceFromParent<ParentCommand, Self, Value> {
        .init(keyPath: keyPath)
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolInvocationSummary {
/// Summary node that lets a subcommand intentionally render a property-wrapper value owned by its parent command.
public struct InvocationSummaryValueReferenceFromParent<Parent: AnyCommandLineTool, Command: AnyCommandLineTool, Value: InvocationSummaryValue>: InvocationSummary where Command: _InvocationSummarySubcommandWithParentCommand, Parent == Command.ParentCommand {
    let keyPath: KeyPath<Parent, Value>

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
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

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        let parent: Parent = try _requireInvocationSummaryParent(parent, for: Command.self)

        let resolved = try parent[keyPath: keyPath].resolve(
            in: .init(
                resolvingID: InvocationSummaryContext.argumentID(command: parent, keyPath: keyPath),
                defaultKeyConversion: parent.keyConversion
            )
        )
        let components = resolved.publicInvocationComponents
        let shouldRender = try context.registerHandledValueReference(
            command: parent,
            keyPath,
            disposition: .explicitRender,
            defaultPosition: resolved.defaultPosition,
            components: components
        )

        return shouldRender ? components : []
    }
}

}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolInvocationSummary.InvocationSummaryValueReferenceFromParent: CommandLineToolInvocationSummary._InvocationSummaryApplicabilityTarget {
    public func _registerArgumentApplicability(
        command: Command,
        parent: AnyCommandLineTool?,
        context: CommandLineToolInvocationSummary.InvocationSummaryContext,
        otherwise: _CommandLineToolArgumentApplicability<Command>.Otherwise,
        location: SourceCodeLocation?
    ) throws {
        let parent: Parent = try _requireInvocationSummaryParent(parent, for: Command.self, location: location)
        let argumentID = CommandLineToolInvocationSummary.InvocationSummaryContext.argumentID(command: parent, keyPath: keyPath)
        let resolved = try parent[keyPath: keyPath].resolve(
            in: .init(
                resolvingID: argumentID,
                defaultKeyConversion: parent.keyConversion
            )
        )
        let components = resolved.publicInvocationComponents

        switch otherwise {
            case .omit(let reason):
                try context.registerHandledValueReference(
                    command: parent,
                    keyPath,
                    disposition: .omitted,
                    reason: reason,
                    location: location
                )
            case .unavailable(let reason):
                try context.registerHandledValueReference(
                    command: parent,
                    keyPath,
                    disposition: .unavailable,
                    defaultPosition: resolved.defaultPosition,
                    components: components,
                    reason: reason,
                    location: location
                )

                guard components.allSatisfy({ $0.argumentValues.isEmpty }) else {
                    throw CommandLineToolInvocationSummary.Error.unsupportedArgument(
                        command: parent.commandName,
                        argument: argumentID,
                        disposition: .unavailable,
                        components: components,
                        reason: reason,
                        location: location
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
extension CommandLineToolInvocationSummary._Unavailable where Command: _InvocationSummarySubcommandWithParentCommand {
    public init<Parent: AnyCommandLineTool>(
        _ reference: CommandLineToolInvocationSummary.InvocationSummaryValueReferenceFromParent<Parent, Command, Value>,
        reason: String? = nil,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil
    ) where Parent == Command.ParentCommand {
        let location = SourceCodeLocation(fileID: fileID, function: function, line: line, column: column)

        self.validate = { _, parent, context in
            let parent: Parent = try _requireInvocationSummaryParent(parent, for: Command.self, location: location)

            let argumentID = CommandLineToolInvocationSummary.InvocationSummaryContext.argumentID(command: parent, keyPath: reference.keyPath)
            let resolved = try parent[keyPath: reference.keyPath].resolve(
                in: .init(
                    resolvingID: argumentID,
                    defaultKeyConversion: parent.keyConversion
                )
            )
            let components = resolved.publicInvocationComponents

            try context.registerHandledValueReference(
                command: parent,
                reference.keyPath,
                disposition: .unavailable,
                defaultPosition: resolved.defaultPosition,
                components: components,
                reason: reason,
                location: location
            )

            guard components.allSatisfy({ $0.argumentValues.isEmpty }) else {
                throw CommandLineToolInvocationSummary.Error.unsupportedArgument(
                    command: parent.commandName,
                    argument: argumentID,
                    disposition: .unavailable,
                    components: components,
                    reason: reason,
                    location: location
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
extension CommandLineToolInvocationSummary.Omit where Command: _InvocationSummarySubcommandWithParentCommand, Content: CommandLineToolInvocationSummary.InvocationSummaryValue {
    public init<Parent: AnyCommandLineTool>(
        _ reference: CommandLineToolInvocationSummary.InvocationSummaryValueReferenceFromParent<Parent, Command, Content>,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil
    ) where Parent == Command.ParentCommand {
        let location = SourceCodeLocation(fileID: fileID, function: function, line: line, column: column)

        self.init(_makeComponents: { _, parent, context in
            let parent: Parent = try _requireInvocationSummaryParent(parent, for: Command.self, location: location)

            try context.registerHandledValueReference(
                command: parent,
                reference.keyPath,
                disposition: .omitted,
                location: location
            )

            return []
        })
    }
}

private func _requireInvocationSummaryParent<Parent: AnyCommandLineTool, Command: AnyCommandLineTool>(
    _ parent: AnyCommandLineTool?,
    for command: Command.Type,
    location: SourceCodeLocation? = nil
) throws -> Parent {
    guard let parent = parent as? Parent else {
        throw CommandLineToolInvocationSummary.Error.missingExpectedParent(
            command: Command.self,
            expectedParent: Parent.self,
            actualParent: parent.map { Swift.type(of: $0) },
            location: location
        )
    }

    return parent
}
