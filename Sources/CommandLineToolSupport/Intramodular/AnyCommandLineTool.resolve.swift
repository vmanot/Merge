#if os(macOS)
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

//    public var _resolvedDescriptionChain: [_ResolvedCommandLineToolDescription] {
//        get throws {
//            var resolvedDescriptions = [_ResolvedCommandLineToolDescription]()
//
//            switch self {
//                case _ as any _GenericSubcommandProtocol:
//                    var argumentPositions: Set<_CommandLineToolArgumentPosition> = [.local, .nextCommand, .lastCommand]
//                    var root: AnyCommandLineTool! = self
//                    var depth = 0
//
//                    resolvedDescriptions.append(
//                        try self.resolve(
//                            in: _CommandLineToolResolutionContext(
//                                argumentPositions: argumentPositions,
//                                traverseDepth: depth
//                            )
//                        )
//                    )
//
//                    while let parent = (root as? (any _GenericSubcommandProtocol))?.parent {
//                        depth += 1
//                        defer { root = parent }
//
//                        if (parent is any _GenericSubcommandProtocol) == false {
//                            argumentPositions.remove(.nextCommand)
//                        }
//
//                        if depth > 0 {
//                            argumentPositions.remove(.lastCommand)
//                        }
//
//                        try resolvedDescriptions.insert(
//                            parent.resolve(
//                                in: _CommandLineToolResolutionContext(
//                                    argumentPositions: argumentPositions,
//                                    traverseDepth: depth
//                                )
//                            ),
//                            at: 0
//                        )
//                    }
//                default:
//                    resolvedDescriptions.append(
//                        try self.resolve(
//                            in: _CommandLineToolResolutionContext(
//                                argumentPositions: [.local],
//                                traverseDepth: 0
//                            )
//                        )
//                    )
//            }
//
//            return resolvedDescriptions
//        }
//    }

    public func resolve() throws -> _ResolvedCommandLineToolDescription {
        let mirror = try InstanceMirror(reflecting: self)

        var _resolvedArguments: _ResolvedCommandLineToolDescription.ResolvedArguments = []
        var _resolvedSubcommmands: _ResolvedCommandLineToolDescription.ResolvedSubcommands = []

//        try _resolveArgumentsFromParentCommand(context: context, into: &_resolvedArguments)

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
                    commandName: _commandName
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
            toolName: _commandName,
            arguments: _resolvedArguments,
            subcommands: _resolvedSubcommmands
        )
    }

//    private func _resolveArgumentsFromParentCommand(
//        context: _CommandLineToolResolutionContext,
//        into resolved: inout _ResolvedCommandLineToolDescription.ResolvedArguments
//    ) throws {
//        var parent: AnyCommandLineTool? = (self as? any _GenericSubcommandProtocol)?.parent
//        var depth = context.traverseDepth + 1
//
//        if let parent, context.argumentPositions.contains(.nextCommand) {
//            // subcommmand inherits arguments with `defaultPosition` of `.nextCommand` (aka. the subcommand or this command) from parent command
//            try resolved.append(
//                contentsOf: parent.resolve(
//                    in: _CommandLineToolResolutionContext(
//                        argumentPositions: [.nextCommand],
//                        traverseDepth: depth
//                    )
//                ).localArguments
//            )
//        }
//
//        guard depth == 1 else { return } // If depth > 1, it is an intermediate command, not last command
//        guard context.argumentPositions.contains(.lastCommand) else { return }
//
//        while let _parent = parent {
//            depth += 1
//
//            // Inherits arguments with `defaultPosition` of `.lastCommand` from the parent command chain
//            // For example: `git remote update` chain is `remote` -> `git`
//            try resolved.append(
//                contentsOf: _parent.resolve(
//                    in: _CommandLineToolResolutionContext(
//                        argumentPositions: [.lastCommand],
//                        traverseDepth: depth
//                    )
//                ).localArguments
//            )
//
//            parent = (_parent as? any _GenericSubcommandProtocol)?.parent
//        }
//    }

    private func _resolveSubcommand(
        _ subcommand: any _CommandLineToolSubcommandProtocol,
        resolvingID: _ResolvedCommandLineToolDescription.ArgumentID,
        context: _CommandLineToolResolutionContext,
        into resolved: inout _ResolvedCommandLineToolDescription.ResolvedSubcommands
    ) throws {
        try resolved.append(
            _ResolvedCommandLineToolDescription.Subcommand(
                id: resolvingID,
                name: subcommand.command._commandName,
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

#endif
