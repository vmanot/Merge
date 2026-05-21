//
//  AnyCommandLineTool+Resolve.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/12.
//

import Foundation
import Swallow
import Runtime

extension AnyCommandLineTool {
    package func _defaultInvocationArguments(
        context: CommandLineToolInvocationSummary.InvocationSummaryContext,
        positions: Set<_CommandLineToolArgumentPosition.Anchor>
    ) throws -> [String] {
        try resolve().arguments
            .filter {
                positions.contains($0.defaultPosition.anchor)
            }
            .filter {
                !context.argumentIsRendered(command: self, argumentName: $0.id.rawValue)
            }
            .flatMap { argument in
                defer {
                    context.registerArgument(command: self, argumentName: argument.id.rawValue)
                }

                return argument.invocationArguments
            }
            .filter { !$0.isEmpty }
    }

    public var _resolvedDescriptionChain: [_ResolvedCommandLineToolDescription] {
        get throws {
            guard let command = self as? any CommandLineTool else {
                return [try resolve()]
            }

            return try (command._commandChain ?? [self]).map {
                try $0.resolve()
            }
        }
    }

    public func resolve() throws -> _ResolvedCommandLineToolDescription {
        let mirror = try InstanceMirror(reflecting: self)

        var _resolvedArguments: _ResolvedCommandLineToolDescription.ResolvedArguments = []
        var _resolvedSubcommmands: _ResolvedCommandLineToolDescription.ResolvedSubcommands = []

        if let selectedTool = self as? (any _GenericSelectedCommandLineToolProtocol) {
            let _resolved = try selectedTool._opaqueSelectedTool.resolve()
            _resolvedArguments.append(contentsOf: _resolved.arguments)
            _resolvedSubcommmands.append(contentsOf: _resolved.subcommands)
        } else if let subcommand = self as? (any _GenericSubcommandProtocol) {
            let _resolved = try subcommand.command.resolve()
            _resolvedArguments.append(contentsOf: _resolved.arguments)
            _resolvedSubcommmands.append(contentsOf: _resolved.subcommands)
        } else {
            for (key, value) in mirror.children {
                let resolvingID = _ResolvedCommandLineToolDescription.ArgumentID(
                    rawValue: key.stringValue.dropPrefixIfPresent("_"), // property wrapper always includes a prefix `_`
                    commandName: requireCommandName().rawValue
                )

                let context = _CommandLineToolResolutionContext(
                    resolvingID: resolvingID,
                    defaultKeyConversion: self.keyConversion
                )
                if let parameter = value as? (any _CommandLineToolParameterProtocol) {
                    try _resolvedArguments.append(
                        parameter.resolve(in: context)
                    )
                } else if let flag = value as? (any _CommandLineToolFlagProtocol) {
                    try _resolvedArguments.append(
                        flag.resolve(in: context)
                    )
                } else if let subcommand = value as? (any _CommandLineToolSubcommandProtocol) {
                    try _resolveSubcommand(
                        subcommand,
                        resolvingID: resolvingID,
                        context: context,
                        into: &_resolvedSubcommmands
                    )
                }
            }
        }

        return _ResolvedCommandLineToolDescription(
            commandName: requireCommandName().rawValue,
            arguments: _resolvedArguments,
            subcommands: _resolvedSubcommmands
        )
    }

    private func _resolveSubcommand(
        _ subcommand: any _CommandLineToolSubcommandProtocol,
        resolvingID: _ResolvedCommandLineToolDescription.ArgumentID,
        context: _CommandLineToolResolutionContext,
        into resolved: inout _ResolvedCommandLineToolDescription.ResolvedSubcommands
    ) throws {
        try resolved.append(
            _ResolvedCommandLineToolDescription.Subcommand(
                id: resolvingID,
                name: subcommand.command.requireCommandName().rawValue,
                _resolvedDescription: subcommand.command.resolve()
            )
        )
    }
}

// MARK: - Helpers

extension AnyCommandLineTool {
    private func _effectiveKeyConversion(
        explicit: _CommandLineToolOptionKeyConversion?,
        nameOfKey: String
    ) -> _CommandLineToolOptionKeyConversion {
        explicit ?? keyConversion ?? defaultKeyConversion(nameOfKey)
    }

    private func defaultKeyConversion(_ name: String) -> _CommandLineToolOptionKeyConversion {
        name.count > 1 ? .doubleHyphenPrefixed : .hyphenPrefixed
    }
}
