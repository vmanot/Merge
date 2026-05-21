//
// Copyright (c) Vatsal Manot
//

import Foundation
import Runtime
import Swallow

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct _CommandLineToolReflectionResolver {
    var tool: AnyCommandLineTool

    func resolve() throws -> _ResolvedCommandLineToolDescription {
        if let selectedTool = tool as? any _GenericSelectedCommandLineToolProtocol {
            return try forwardingResolvedDescription(from: selectedTool._opaqueSelectedTool)
        }

        if let subcommand = tool as? any _GenericSubcommandProtocol {
            return try forwardingResolvedDescription(from: subcommand.command)
        }

        return try reflectResolvedDescription()
    }

    private func forwardingResolvedDescription(
        from tool: AnyCommandLineTool
    ) throws -> _ResolvedCommandLineToolDescription {
        let resolved = try tool.resolve()

        return _ResolvedCommandLineToolDescription(
            commandName: self.tool.requireCommandName().rawValue,
            arguments: resolved.arguments,
            subcommands: resolved.subcommands
        )
    }

    private func reflectResolvedDescription() throws -> _ResolvedCommandLineToolDescription {
        let mirror = try InstanceMirror(reflecting: tool)
        var resolvedArguments: _ResolvedCommandLineToolDescription.ResolvedArguments = []
        var resolvedSubcommands: _ResolvedCommandLineToolDescription.ResolvedSubcommands = []

        for (key, value) in mirror.children {
            let resolvingID = _ResolvedCommandLineToolDescription.ArgumentID(
                rawValue: key.stringValue.dropPrefixIfPresent("_"),
                commandName: tool.requireCommandName().rawValue
            )
            let context = _CommandLineToolResolutionContext(
                resolvingID: resolvingID,
                defaultKeyConversion: tool.keyConversion
            )

            try resolve(
                value,
                resolvingID: resolvingID,
                context: context,
                resolvedArguments: &resolvedArguments,
                resolvedSubcommands: &resolvedSubcommands
            )
        }

        return _ResolvedCommandLineToolDescription(
            commandName: tool.requireCommandName().rawValue,
            arguments: resolvedArguments,
            subcommands: resolvedSubcommands
        )
    }

    private func resolve(
        _ value: Any,
        resolvingID: _ResolvedCommandLineToolDescription.ArgumentID,
        context: _CommandLineToolResolutionContext,
        resolvedArguments: inout _ResolvedCommandLineToolDescription.ResolvedArguments,
        resolvedSubcommands: inout _ResolvedCommandLineToolDescription.ResolvedSubcommands
    ) throws {
        if let parameter = value as? any _CommandLineToolParameterProtocol {
            try resolvedArguments.append(parameter.resolve(in: context))
        } else if let flag = value as? any _CommandLineToolFlagProtocol {
            try resolvedArguments.append(flag.resolve(in: context))
        } else if let subcommand = value as? any _CommandLineToolSubcommandProtocol {
            try resolvedSubcommands.append(
                _ResolvedCommandLineToolDescription.Subcommand(
                    id: resolvingID,
                    name: subcommand.command.requireCommandName().rawValue,
                    _resolvedDescription: subcommand.command.resolve()
                )
            )
        }
    }
}
