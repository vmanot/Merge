//
//  AnyCommandLineTool+Resolve.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/12.
//

import Foundation
import Swallow

extension AnyCommandLineTool {
    package func _defaultInvocationArguments(
        context: CommandLineToolInvocationSummary.InvocationSummaryContext,
        positions: Set<_CommandLineToolArgumentPosition.Anchor>
    ) throws -> CommandLineToolInvocation.Arguments {
        CommandLineToolInvocation.Arguments(
            try _defaultInvocationComponents(
                context: context,
                positions: positions
            )
            .flatMap(\.argumentValues)
        )
    }

    package func _defaultInvocationComponents(
        context: CommandLineToolInvocationSummary.InvocationSummaryContext,
        positions: Set<_CommandLineToolArgumentPosition.Anchor>
    ) throws -> [CommandLineToolInvocation.Component] {
        try resolve().arguments
            .filter {
                positions.contains($0.defaultPosition.anchor)
            }
            .filter {
                !context.argumentIsHandled(command: self, argumentName: $0.id.rawValue)
            }
            .flatMap { argument -> [CommandLineToolInvocation.Component] in
                let components = argument.publicInvocationComponents
                let shouldRender = try context.registerHandledArgument(
                    command: self,
                    argumentName: argument.id.rawValue,
                    disposition: .defaultRender,
                    components: components
                )

                return shouldRender ? components : []
            }
    }

    public var _resolvedDescriptionChain: [_ResolvedCommandLineToolDescription] {
        get throws {
            guard let command = self as? any CommandLineTool else {
                return [try resolve()]
            }

            return try _CommandLineToolCommandChain(resolvingOrSelf: command).map {
                try $0.resolve()
            }
        }
    }

    public func resolve() throws -> _ResolvedCommandLineToolDescription {
        try _CommandLineToolReflectionResolver(tool: self).resolve()
    }
}
