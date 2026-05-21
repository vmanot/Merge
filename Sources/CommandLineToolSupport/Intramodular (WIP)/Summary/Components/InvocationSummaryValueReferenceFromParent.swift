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
        guard let parent = parent as? Parent else {
            preconditionFailure("No such parent matched.")
        }

        guard !context.argumentIsRendered(command: parent, keyPath) else {
            return []
        }
        defer { context.registerValueReference(command: parent, keyPath) }

        let resolved = try parent[keyPath: keyPath].resolve(
            in: .init(
                resolvingID: _ResolvedCommandLineToolDescription.ArgumentID(
                    rawValue: InvocationSummaryContext.argumentName(for: keyPath),
                    commandName: parent.requireCommandName().rawValue
                ),
                defaultKeyConversion: parent.keyConversion
            )
        )

        return CommandLineToolInvocation.Arguments(resolved.invocationArgumentValues)
    }
}

}
