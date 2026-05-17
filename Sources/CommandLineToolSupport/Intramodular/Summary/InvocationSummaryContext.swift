#if os(macOS)
//
//  InvocationSummaryContext.swift
//  Merge
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public final class InvocationSummaryContext {
    private(set) var renderedArguments: Set<Argument> = []
    
    struct Argument: Hashable, Sendable {
        var name: String
        var owningCommandName: String
    }
    
    @discardableResult
    func registerValueReference<Command: AnyCommandLineTool, Value: InvocationSummaryValue>(
        command: Command,
        _ keyPath: KeyPath<Command, Value>
    ) -> Bool {
        renderedArguments.insert(
            .init(
                name: String(describing: keyPath).dropPrefixIfPresent("\\\(String(describing: Command.self)).$"),
                owningCommandName: command._commandName
            )
        ).inserted
    }
    
    func argumentIsRendered<Command: AnyCommandLineTool, Value: InvocationSummaryValue>(
        command: Command,
        _ keyPath: KeyPath<Command, Value>
    ) -> Bool {
        renderedArguments.contains(
            .init(
                name: String(describing: keyPath).dropPrefixIfPresent("\\\(String(describing: Command.self)).$"),
                owningCommandName: command._commandName
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
                owningCommandName: command._commandName
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
                owningCommandName: command._commandName
            )
        ).inserted
    }
}

#endif
