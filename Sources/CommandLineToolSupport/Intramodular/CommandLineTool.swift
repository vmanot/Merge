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
    typealias Omit<Content> = CommandLineToolInvocationSummary.Omit<Self, Content>
    typealias _Unavailable<Value> = CommandLineToolInvocationSummary._Unavailable<Self, Value> where Value: CommandLineToolInvocationSummary.InvocationSummaryValue
    typealias Switch<Value, CaseCondition> = CommandLineToolInvocationSummary.InvocationSummarySwitchCondition<Self, Value, CaseCondition> where CaseCondition : CommandLineToolInvocationSummary.InvocationSummarySwitchCaseProtocol, CaseCondition.Command == Self, CaseCondition.Value == Value, Value: CommandLineToolInvocationSummary.InvocationSummaryValue
    typealias Case<Value, Summary> = CommandLineToolInvocationSummary.InvocationSummaryCaseCondition<Self, Value, Summary> where Value : CommandLineToolInvocationSummary.InvocationSummaryValue, Value.WrappedValue: Equatable, Summary : CommandLineToolInvocationSummary.InvocationSummary, Summary.Command == Self
    typealias DefaultCase<Value, Summary> = CommandLineToolInvocationSummary.InvocationSummaryDefaultCaseCondition<Self, Value, Summary> where Value : CommandLineToolInvocationSummary.InvocationSummaryValue, Summary : CommandLineToolInvocationSummary.InvocationSummary, Summary.Command == Self

    @CommandLineToolInvocationSummary.InvocationSummaryBuilder<Command>
    var invocationSummary: SummaryContent { get }
}

extension CommandLineTool {
    public var invocationSummary: some CommandLineToolInvocationSummary.InvocationSummary {
        CommandLineToolInvocationSummary.DefaultInvocationSummary<Self>()
    }

    public func invocationArgumentValues(
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        CommandLineToolInvocation.Arguments(
            try invocationComponents(context: context).flatMap(\.argumentValues)
        )
    }

    public func invocationComponents(
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        let subject = _invocationSummarySubject()
        let summaryComponents = try invocationSummary.makeInvocationComponents(
            command: subject.summaryCommand,
            parent: subject.parent,
            context: context
        )
        var components: [CommandLineToolInvocation.Component] = []

        if let chain = subject.commandChain {
            components.append(
                contentsOf: try _CommandLineToolInvocationAssembly(
                    chain: chain,
                    leafComponents: summaryComponents,
                    context: context
                )
                .makeInvocationComponents()
            )
        } else {
            components.append(.executable(CommandLineToolInvocation.Argument(requireCommandName().rawValue)))
            components.append(contentsOf: summaryComponents)
        }

        if _shouldAppendDefaultInvocationSummary {
            try components.append(
                contentsOf: CommandLineToolInvocationSummary.DefaultInvocationSummary<Self>().makeInvocationComponents(
                    command: self,
                    parent: nil,
                    context: context
                )
            )
        }

        var invocation = CommandLineToolInvocation(
            components: components.filter { !$0.argumentValues.isEmpty }
        )
        let hostedComponents = try _CommandLineToolCommandChain(resolvingOrSelf: self).applyingAttachedHostToolIfNeeded(
            to: invocation.componentList,
            context: context
        )

        if hostedComponents.elements != invocation.components {
            invocation = CommandLineToolInvocation(components: hostedComponents)
        }

        try context.applyRewriteRules(to: &invocation)

        return invocation.components
    }

    public func invocationArguments(context: CommandLineToolInvocationSummary.InvocationSummaryContext) throws -> [String] {
        try invocationArgumentValues(context: context).rawValues
    }

    public func invocationSummaryComponents(
        for keyPaths: [PartialKeyPath<Self>]
    ) throws -> CommandLineToolInvocation.Components {
        let context = CommandLineToolInvocationSummary.InvocationSummaryContext()

        _ = try invocationComponents(context: context)

        return context.invocationComponents(
            for: keyPaths,
            command: self
        )
    }

    public func identifiedInvocationSummaryComponents(
        for keyPaths: [PartialKeyPath<Self>]
    ) throws -> [_ResolvedCommandLineToolDescription.IdentifiedInvocationComponent] {
        let context = CommandLineToolInvocationSummary.InvocationSummaryContext()

        _ = try invocationComponents(context: context)

        return context.identifiedInvocationComponents(
            for: keyPaths,
            command: self
        )
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
