//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation

extension CommandLineToolInvocationSummary {
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Tracks arguments already rendered by explicit summary nodes so default rendering can avoid duplicates.
public final class InvocationSummaryContext {
    private(set) var renderedArguments: Set<Argument> = []

    struct Argument: Hashable, Sendable {
        var name: String
        var owningCommandName: String
    }

    static func argumentName<Command: AnyCommandLineTool, Value: InvocationSummaryValue>(
        for keyPath: KeyPath<Command, Value>
    ) -> String {
        String(describing: keyPath).dropPrefixIfPresent("\\\(String(describing: Command.self)).$")
    }

    @discardableResult
    func registerValueReference<Command: AnyCommandLineTool, Value: InvocationSummaryValue>(
        command: Command,
        _ keyPath: KeyPath<Command, Value>
    ) -> Bool {
        renderedArguments.insert(
            .init(
                name: Self.argumentName(for: keyPath),
                owningCommandName: command.requireCommandName().rawValue
            )
        ).inserted
    }

    func argumentIsRendered<Command: AnyCommandLineTool, Value: InvocationSummaryValue>(
        command: Command,
        _ keyPath: KeyPath<Command, Value>
    ) -> Bool {
        renderedArguments.contains(
            .init(
                name: Self.argumentName(for: keyPath),
                owningCommandName: command.requireCommandName().rawValue
            )
        )
    }

    func argumentIsRendered<Command: AnyCommandLineTool>(
        command: Command,
        argumentName: String
    ) -> Bool {
        renderedArguments.contains(
            .init(
                name: argumentName,
                owningCommandName: command.requireCommandName().rawValue
            )
        )
    }

    @discardableResult
    func registerArgument<Command: AnyCommandLineTool>(
        command: Command,
        argumentName: String
    ) -> Bool {
        renderedArguments.insert(
            .init(
                name: argumentName,
                owningCommandName: command.requireCommandName().rawValue
            )
        ).inserted
    }
}

}

#endif
