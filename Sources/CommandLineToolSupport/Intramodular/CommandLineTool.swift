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
        RuntimeReflectionInvocationSummary()
    }
    
    public var invocationArguments: [String] {
        get throws {
            switch self {
                case let command as SummaryContent.Command:
                    return try invocationSummary.invocationArguments(for: command)
                case let subcommand as any _GenericSubcommandProtocol:
                    guard let command = subcommand.command as? SummaryContent.Command else {
                        preconditionFailure("GenericSubcommand \(type(of: subcommand.command)) not equals to \(SummaryContent.Command.self)")
                    }
                    
                    let parentCommandInvocationArgs = try (subcommand.parent as? any CommandLineTool)?.invocationArguments
                    return try (parentCommandInvocationArgs ?? []) + invocationSummary.invocationArguments(for: command)
                default:
                    preconditionFailure("\(type(of: self)) not equals to \(SummaryContent.Command.self)")
            }
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
