//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge
import Swift

/// A type that wraps a command line tool.
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol CommandLineTool: AnyCommandLineTool {
    associatedtype EnvironmentVariables = _CommandLineTool_DefaultEnvironmentVariables
    associatedtype Command : AnyCommandLineTool = Self

    associatedtype SummaryContent: CommandLineToolInvocationSummary.InvocationSummary
    typealias When = CommandLineToolInvocationSummary.InvocationSummaryWhenCondition<Self>
    typealias Switch<Value, CaseCondition> = CommandLineToolInvocationSummary.InvocationSummarySwitchCondition<Self, Value, CaseCondition> where CaseCondition : CommandLineToolInvocationSummary.InvocationSummarySwitchCaseProtocol, CaseCondition.Command == Self, CaseCondition.Value == Value, Value: CommandLineToolInvocationSummary.InvocationSummaryValue
    typealias Case<Value, Summary> = CommandLineToolInvocationSummary.InvocationSummaryCaseCondition<Self, Value, Summary> where Value : CommandLineToolInvocationSummary.InvocationSummaryValue, Value.WrappedValue: Equatable, Summary : CommandLineToolInvocationSummary.InvocationSummary, Summary.Command == Self
    typealias DefaultCase<Value, Summary> = CommandLineToolInvocationSummary.InvocationSummaryDefaultCaseCondition<Self, Value, Summary> where Value : CommandLineToolInvocationSummary.InvocationSummaryValue, Summary : CommandLineToolInvocationSummary.InvocationSummary, Summary.Command == Self

    @CommandLineToolInvocationSummary.InvocationSummaryBuilder<Command>
    var invocationSummary: SummaryContent { get }
}

extension CommandLineTool {
    var _commandChain: [AnyCommandLineTool]? {
        if let selectedTool = self as? any _GenericSelectedCommandLineToolProtocol {
            return [
                selectedTool._opaqueSelectingTool,
                self
            ]
        }

        guard let subcommand = self as? any _GenericSubcommandProtocol else {
            return nil
        }

        var result: [AnyCommandLineTool] = [subcommand._opaqueCommand]
        var parent = subcommand._opaqueParent

        while true {
            if let parentSubcommand = parent as? any _GenericSubcommandProtocol {
                result.insert(parentSubcommand._opaqueCommand, at: 0)
                parent = parentSubcommand._opaqueParent
            } else if let selectedTool = parent as? any _GenericSelectedCommandLineToolProtocol {
                guard let selectedToolWrapper = selectedTool as? AnyCommandLineTool else {
                    preconditionFailure("Unable to resolve selected tool wrapper for \(type(of: selectedTool))")
                }

                result.insert(selectedToolWrapper, at: 0)
                parent = selectedTool._opaqueSelectingTool
            } else {
                break
            }
        }

        result.insert(parent, at: 0)

        return result
    }

    private var _commandChainOrSelf: [AnyCommandLineTool] {
        _commandChain ?? [self]
    }

    private var _attachedHostToolInCommandChain: (selectedTool: AnyCommandLineTool, hostTool: AnyCommandLineTool._AttachedToolHost)? {
        _commandChainOrSelf.lazy.compactMap { tool in
            tool._attachedHostTool.map { (tool, $0) }
        }.first
    }

    func _selectedToolInvocation(
        renderedInvocation: CommandLineToolInvocation
    ) -> _CommandLineToolSelectedToolInvocation? {
        if
            let chain = _commandChain,
            let selectingToolIndex = chain.firstIndex(where: { $0 is AnyCommandLineToolWithSelectedTool }),
            chain.indices.contains(selectingToolIndex + 1),
            let selectingTool = chain[selectingToolIndex] as? AnyCommandLineToolWithSelectedTool
        {
            let selectedToolCommandPath = chain[(selectingToolIndex + 1)...]
                .map { $0.requireCommandName().rawValue }

            guard let selectedToolCommandName = selectedToolCommandPath.first else {
                return nil
            }

            return _CommandLineToolSelectedToolInvocation(
                renderedInvocation: renderedInvocation,
                selectingToolCommandName: selectingTool.requireCommandName().rawValue,
                selectedToolCommandName: selectedToolCommandName,
                selectedToolCommandPath: selectedToolCommandPath,
                selectionSemantics: selectingTool.toolSelectionSemantics,
                resolutionSemantics: selectingTool.selectedToolResolutionSemantics
            )
        }

        if let selectedToolInvocation = _attachedHostToolSelectedToolInvocation(renderedInvocation: renderedInvocation) {
            return selectedToolInvocation
        }

        return nil
    }

    private func _attachedHostToolSelectedToolInvocation(
        renderedInvocation: CommandLineToolInvocation
    ) -> _CommandLineToolSelectedToolInvocation? {
        let chain = _commandChainOrSelf

        guard
            let selectedToolIndex = chain.firstIndex(where: { $0._attachedHostTool != nil }),
            let hostTool = chain[selectedToolIndex]._attachedHostTool
        else {
            return nil
        }

        let selectedToolCommandPath = chain[selectedToolIndex...].enumerated().map { offset, command in
            if offset == 0 {
                return hostTool._selectedToolCommandNameOverride ?? command.requireCommandName().rawValue
            } else {
                return command.requireCommandName().rawValue
            }
        }

        guard let selectedToolCommandName = selectedToolCommandPath.first else {
            return nil
        }

        let selectingTool = hostTool._selectingTool

        return _CommandLineToolSelectedToolInvocation(
            renderedInvocation: renderedInvocation,
            selectingToolCommandName: selectingTool.requireCommandName().rawValue,
            selectedToolCommandName: selectedToolCommandName,
            selectedToolCommandPath: selectedToolCommandPath,
            selectionSemantics: selectingTool.toolSelectionSemantics,
            resolutionSemantics: selectingTool.selectedToolResolutionSemantics
        )
    }

    private func _applyingAttachedHostToolIfNeeded(
        to arguments: CommandLineToolInvocation.Arguments,
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        guard let (selectedTool, hostTool) = _attachedHostToolInCommandChain else {
            return arguments
        }

        return try hostTool._invocationArguments(
            hosting: arguments,
            selectedTool: selectedTool,
            context: context
        )
    }

    private func _sanitizeInvocationArguments(
        _ arguments: CommandLineToolInvocation.Arguments
    ) -> CommandLineToolInvocation.Arguments {
        CommandLineToolInvocation.Arguments(
            arguments.elements.filter { !$0.rawValue.isEmpty }
        )
    }

    private func _makeCommandChainInvocationArguments(
        chain: [AnyCommandLineTool],
        leafArguments: CommandLineToolInvocation.Arguments,
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        guard let root = chain.first else {
            return leafArguments
        }

        var arguments = CommandLineToolInvocation.Arguments()

        arguments.elements.append(CommandLineToolInvocation.Argument(root.requireCommandName().rawValue))
        try arguments.append(
            contentsOf: root._defaultInvocationArguments(
                context: context,
                positions: [.local]
            )
        )

        for (index, command) in chain.dropFirst().enumerated() {
            let parent = chain[index]

            arguments.elements.append(CommandLineToolInvocation.Argument(command.requireCommandName().rawValue))
            try arguments.append(
                contentsOf: parent._defaultInvocationArguments(
                    context: context,
                    positions: [.nextCommand]
                )
            )

            if index < chain.count - 2 {
                try arguments.append(
                    contentsOf: command._defaultInvocationArguments(
                        context: context,
                        positions: [.local]
                    )
                )
            }
        }

        arguments.elements.append(contentsOf: leafArguments.elements.filter { !$0.rawValue.isEmpty })

        for command in chain.dropLast() {
            try arguments.append(
                contentsOf: command._defaultInvocationArguments(
                    context: context,
                    positions: [.lastCommand]
                )
            )
        }

        return arguments
    }

    public var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        CommandLineToolInvocationSummary.DefaultInvocationSummary<Self>()
    }

    public func invocationArgumentValues(
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        var arguments = CommandLineToolInvocation.Arguments()

        switch self {
            case let command as SummaryContent.Command:
                try arguments.append(
                    contentsOf: CommandLineToolInvocation.Arguments([requireCommandName().rawValue]) + invocationSummary.makeInvocationArguments(
                        command: command,
                        parent: nil,
                        context: context
                    )
                )
            case let selectedTool as any _GenericSelectedCommandLineToolProtocol:
                guard let chain = _commandChain else {
                    preconditionFailure("Unable to resolve selected tool chain for \(type(of: self))")
                }
                guard let command = selectedTool._opaqueSelectedTool as? SummaryContent.Command else {
                    preconditionFailure("GenericSelectedCommandLineTool \(type(of: selectedTool._opaqueSelectedTool)) not equals to \(SummaryContent.Command.self)")
                }
                let selfArgs = try invocationSummary.makeInvocationArguments(
                    command: command,
                    parent: selectedTool._opaqueSelectingTool,
                    context: context
                )

                arguments.append(
                    contentsOf: try _makeCommandChainInvocationArguments(
                        chain: chain,
                        leafArguments: CommandLineToolInvocation.Arguments(selfArgs),
                        context: context
                    )
                )
            case let subcommand as any _GenericSubcommandProtocol:
                guard let chain = _commandChain else {
                    preconditionFailure("Unable to resolve subcommand chain for \(type(of: self))")
                }
                guard let command = subcommand.command as? SummaryContent.Command else {
                    preconditionFailure("GenericSubcommand \(type(of: subcommand.command)) not equals to \(SummaryContent.Command.self)")
                }
                let selfArgs = try invocationSummary.makeInvocationArguments(
                    command: command,
                    parent: subcommand.parent,
                    context: context
                )

                arguments.append(
                    contentsOf: try _makeCommandChainInvocationArguments(
                        chain: chain,
                        leafArguments: CommandLineToolInvocation.Arguments(selfArgs),
                        context: context
                    )
                )
            default:
                preconditionFailure("\(type(of: self)) not equals to \(SummaryContent.Command.self)")
        }

        if !(self is any _GenericSubcommandProtocol) && !(self is any _GenericSelectedCommandLineToolProtocol) && !(SummaryContent.self == CommandLineToolInvocationSummary.DefaultInvocationSummary<Self>.self) {
            try arguments.append(
                contentsOf: CommandLineToolInvocationSummary.DefaultInvocationSummary<Self>().makeInvocationArguments(
                    command: self,
                    parent: nil,
                    context: context
                )
            )
        }

        return try _applyingAttachedHostToolIfNeeded(
            to: _sanitizeInvocationArguments(arguments),
            context: context
        )
    }

    public func invocationArguments(context: CommandLineToolInvocationSummary.InvocationSummaryContext) throws -> [String] {
        try invocationArgumentValues(context: context).rawValues
    }

    public var invocation: String {
        get throws {
            try invocationArgumentValues(context: CommandLineToolInvocationSummary.InvocationSummaryContext()).description
        }
    }

    public func callAsFunction() async throws -> Process.RunResult {
        try await withUnsafeSystemShell { shell in
            try await shell.run(command: self.invocation)
        }
    }

}

extension CommandLineTool {
    public func with<T>(
        _ keyPath: WritableKeyPath<Self, T>,
        _ newValue: T
    ) -> Self {
        var copy = self
        copy[keyPath: keyPath] = newValue
        return copy
    }
}
