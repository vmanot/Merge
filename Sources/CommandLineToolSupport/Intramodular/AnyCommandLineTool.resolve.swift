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
        let arguments = try resolve().arguments
            .filter {
                positions.contains($0.defaultPosition.anchor)
            }
            .filter {
                !context.argumentIsRendered(command: self, argumentName: $0.id.rawValue)
            }
            .flatMap { argument -> [CommandLineToolInvocation.Argument] in
                defer {
                    context.registerArgument(command: self, argumentName: argument.id.rawValue)
                }

                return argument.invocationArgumentValues
            }
            .filter { !$0.rawValue.isEmpty }

        return CommandLineToolInvocation.Arguments(arguments)
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
