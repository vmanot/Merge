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
    
    associatedtype SummaryContent: InvocationSummary
    typealias When = InvocationSummaryWhenCondition<Self>
    typealias Switch<Value, CaseCondition> = InvocationSummarySwitchCondition<Self, Value, CaseCondition> where CaseCondition : InvocationSummarySwitchCaseProtocol, Value: InvocationSummaryValue
    typealias Case<Value, Summary> = InvocationSummaryCaseCondition<Self, Value, Summary> where Value : InvocationSummaryValue, Summary : InvocationSummary
    typealias DefaultCase<Value, Summary> = InvocationSummaryDefaultCaseCondition<Self, Value, Summary> where Value : InvocationSummaryValue, Summary : InvocationSummary
    
    @InvocationSummaryBuilder<Command>
    var invocationSummary: SummaryContent { get }
}

extension CommandLineTool {
    public var invocationSummary: some InvocationSummary {
        DefaultInvocationSummary<Self>()
    }
    
    public func invocationArguments(context: InvocationSummaryContext) throws -> [String] {
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
                guard let command = subcommand.command as? SummaryContent.Command else {
                    preconditionFailure("GenericSubcommand \(type(of: subcommand.command)) not equals to \(SummaryContent.Command.self)")
                }
                let selfArgs = try invocationSummary.makeInvocationArguments(
                    command: command,
                    parent: subcommand.parent,
                    context: context
                )
                
                let parentArgs = try (subcommand.parent as? any CommandLineTool)?
                    .invocationArguments(context: context)
                
                arguments.append(
                    contentsOf: (parentArgs ?? []) + [_commandName] + selfArgs
                )
            default:
                preconditionFailure("\(type(of: self)) not equals to \(SummaryContent.Command.self)")
        }
        
        if !(SummaryContent.self == DefaultInvocationSummary<Self>.self) {
            try arguments.append(
                contentsOf: DefaultInvocationSummary<Self>().makeInvocationArguments(
                    command: self,
                    parent: nil,
                    context: context
                )
            )
        }
        
        return arguments
    }

    public var invocation: String {
        get throws {
            try invocationArguments(context: InvocationSummaryContext()).joined(separator: " ")
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
