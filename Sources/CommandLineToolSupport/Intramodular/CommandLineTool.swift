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
    
    associatedtype SummaryContent: InvocationSummary
    typealias Summary = CommandLineToolInvocationSummary<Self>
    var invocationSummary: SummaryContent { get }
}

extension CommandLineTool {
    public var invocationSummary: some InvocationSummary {
        RuntimeReflectionInvocationSummary<Self>()
    }
    
    public var invocationArguments: [String] {
        get throws {
            try _invocationArguments(emissionState: InvocationSummaryEmissionState())
        }
    }
    
    private func _invocationArguments(
        emissionState: InvocationSummaryEmissionState
    ) throws -> [String] {
        switch self {
            case let command as SummaryContent.Command:
                let context = InvocationSummaryContext(
                    command: command,
                    parent: nil,
                    emissionState: emissionState
                )
                return try [_commandName] + invocationSummary.makeInvocationArguments(context: context)
            case let subcommand as any _GenericSubcommandProtocol:
                guard let command = subcommand.command as? SummaryContent.Command else {
                    preconditionFailure("GenericSubcommand \(type(of: subcommand.command)) not equals to \(SummaryContent.Command.self)")
                }
                
                let context = InvocationSummaryContext(
                    command: command,
                    parent: subcommand.parent,
                    emissionState: emissionState
                )
                let invocationArgs = try invocationSummary.makeInvocationArguments(context: context)
                let parentCommandInvocationArgs = try (subcommand.parent as? any CommandLineTool)?._invocationArguments(emissionState: emissionState)
                return (parentCommandInvocationArgs ?? []) + [_commandName] + invocationArgs
            default:
                preconditionFailure("\(type(of: self)) not equals to \(SummaryContent.Command.self)")
        }
    }
    
    public var invocation: String {
        get throws {
            try invocationArguments.joined(separator: " ")
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
