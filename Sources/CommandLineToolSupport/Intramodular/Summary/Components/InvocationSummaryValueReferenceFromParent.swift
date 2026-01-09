//
//  InvocationSummaryValueReferenceFromParent.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/9.
//

import Foundation
import Swallow

public struct InvocationSummaryValueReferenceFromParent<Parent: AnyCommandLineTool, Command: AnyCommandLineTool, Value: InvocationSummaryValue>: InvocationSummary where Command : _Subcommand, Parent == Command.ParentCommand {
    let keyPath: KeyPath<Parent, Value>
    
    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [String] {
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
                    rawValue: UUID().uuidString, // construct a temporary string.
                    commandName: parent._commandName
                ),
                defaultKeyConversion: command.keyConversion
            )
        )
        
        if let argument = resolved.invocationArgument {
            return [argument]
        } else {
            return []
        }
    }
}
