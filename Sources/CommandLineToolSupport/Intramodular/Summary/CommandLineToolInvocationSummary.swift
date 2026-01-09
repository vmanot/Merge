//
//  CommandLineToolInvocationSummary.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

public protocol InvocationSummary<Command> {
    associatedtype Command: AnyCommandLineTool
    typealias Context = InvocationSummaryContext
    
    func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: Context
    ) throws -> [String]
}

// MARK: - Supplementary

public struct CommandLineToolInvocationSummary<Command: AnyCommandLineTool>: InvocationSummary {
    let _components: [any InvocationSummary<Command>]

    public init(
        @InvocationSummaryBuilder<Command> _ content: () -> [any InvocationSummary<Command>]
    ) {
        self._components = content()
    }

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [String] {
        try _components.flatMap({
            try $0.makeInvocationArguments(command: command, parent: parent, context: context)
        })
    }
}
