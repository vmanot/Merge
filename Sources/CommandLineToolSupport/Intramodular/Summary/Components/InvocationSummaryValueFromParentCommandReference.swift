//
//  InvocationSummaryValueFromParentCommandReference.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/9.
//


import Foundation
import Swallow

public struct InvocationSummaryValueFromParentCommandReference<Parent: AnyCommandLineTool, Command: AnyCommandLineTool, Value: InvocationSummaryValue>: InvocationSummary {    
    let keyPath: KeyPath<Parent, InvocationSummaryValueReference<Parent, Value>>
    
    public func makeInvocationArguments(context: InvocationSummaryContext<Command>) throws -> [String] {
        guard let parent = context.parent(of: Parent.self) else {
            assertionFailure("Invocation summary expected parent \(Parent.self) but none was found.")
            return []
        }
        
        let reference = parent[keyPath: keyPath]
        let resolved = try reference.value.resolve(
            in: .init(
                resolvingID: _ResolvedCommandLineToolDescription.ArgumentID(
                    rawValue: UUID().uuidString,
                    commandName: parent._commandName
                ),
                defaultKeyConversion: parent.keyConversion
            )
        )
        
        if let argument = resolved.invocationArgument {
            return [argument]
        } else {
            return []
        }
    }
}
