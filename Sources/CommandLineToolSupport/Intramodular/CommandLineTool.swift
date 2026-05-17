#if os(macOS)
//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift
import Merge

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
    private var _subcommandChain: [AnyCommandLineTool]? {
        guard let subcommand = self as? any _GenericSubcommandProtocol else {
            return nil
        }

        var result: [AnyCommandLineTool] = [subcommand._opaqueCommand]
        var parent = subcommand._opaqueParent

        while let parentSubcommand = parent as? any _GenericSubcommandProtocol {
            result.insert(parentSubcommand._opaqueCommand, at: 0)
            parent = parentSubcommand._opaqueParent
        }

        result.insert(parent, at: 0)

        return result
    }

    private func _sanitizeInvocationArguments(_ arguments: [String]) -> [String] {
        arguments.filter { !$0.isEmpty }
    }

    public var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        CommandLineToolInvocationSummary.DefaultInvocationSummary<Self>()
    }

    public func invocationArguments(context: CommandLineToolInvocationSummary.InvocationSummaryContext) throws -> [String] {
        var arguments = [String]()

        switch self {
            case let command as SummaryContent.Command:
                try arguments.append(
                    contentsOf: [_commandName] + invocationSummary.makeInvocationArguments(
                        command: command,
                        parent: nil,
                        context: context
                    )
                )
            case let subcommand as any _GenericSubcommandProtocol:
                guard let chain = _subcommandChain, let root = chain.first else {
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

                arguments.append(root._commandName)
                try arguments.append(
                    contentsOf: root._defaultInvocationArguments(
                        context: context,
                        positions: [.local]
                    )
                )

                for (index, command) in chain.dropFirst().enumerated() {
                    let parent = chain[index]

                    arguments.append(command._commandName)
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

                arguments.append(contentsOf: selfArgs.filter { !$0.isEmpty })

                for command in chain.dropLast() {
                    try arguments.append(
                        contentsOf: command._defaultInvocationArguments(
                            context: context,
                            positions: [.lastCommand]
                        )
                    )
                }
            default:
                preconditionFailure("\(type(of: self)) not equals to \(SummaryContent.Command.self)")
        }

        if !(self is any _GenericSubcommandProtocol) && !(SummaryContent.self == CommandLineToolInvocationSummary.DefaultInvocationSummary<Self>.self) {
            try arguments.append(
                contentsOf: CommandLineToolInvocationSummary.DefaultInvocationSummary<Self>().makeInvocationArguments(
                    command: self,
                    parent: nil,
                    context: context
                )
            )
        }

        return _sanitizeInvocationArguments(arguments)
    }

    public var invocation: String {
        get throws {
            try invocationArguments(context: CommandLineToolInvocationSummary.InvocationSummaryContext()).joined(separator: " ")
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

public enum CommandLineTools {

}

// MARK: - Supplementary

public typealias CLT = CommandLineTools

// MARK: - Auxiliary

public struct _CommandLineTool_DefaultEnvironmentVariables {

}

#endif
