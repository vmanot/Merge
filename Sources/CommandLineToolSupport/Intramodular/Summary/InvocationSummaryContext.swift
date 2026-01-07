//
//  InvocationSummaryContext.swift
//  Merge
//

import Foundation

public struct InvocationSummaryContext<Command: AnyCommandLineTool> {
    public let command: Command
    public let parent: AnyCommandLineTool?

    public init(command: Command, parent: AnyCommandLineTool?) {
        self.command = command
        self.parent = parent
    }

    public func parent<Parent: AnyCommandLineTool>(of type: Parent.Type = Parent.self) -> Parent? {
        var current = parent

        while let candidate = current {
            if let typed = candidate as? Parent {
                return typed
            }

            if let subcommand = candidate as? any _GenericSubcommandProtocol {
                if let command = subcommand.command as? Parent {
                    return command
                }

                current = subcommand.parent
                continue
            }

            break
        }

        return nil
    }
}
