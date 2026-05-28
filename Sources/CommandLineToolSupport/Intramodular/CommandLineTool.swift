//
// Copyright (c) Vatsal Manot
//

import Foundation
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

    typealias InvocationSummary = CommandLineToolInvocationSummary.InvocationSummary
    typealias InvocationSummaryBuilder<Command: AnyCommandLineTool> = CommandLineToolInvocationSummary.InvocationSummaryBuilder<Command>
    typealias InvocationSummaryContext = CommandLineToolInvocationSummary.InvocationSummaryContext
    typealias InvocationSummaryCondition = CommandLineToolInvocationSummary.InvocationSummaryCondition<Self>
    typealias InvocationSummaryValue = CommandLineToolInvocationSummary.InvocationSummaryValue
    typealias InvocationSummaryValueReference<Value> = CommandLineToolInvocationSummary.InvocationSummaryValueReference<Self, Value> where Value: CommandLineToolInvocationSummary.InvocationSummaryValue
    typealias When = CommandLineToolInvocationSummary.InvocationSummaryWhenCondition<Self>
    typealias Omit<Content> = CommandLineToolInvocationSummary.Omit<Self, Content>
    typealias _Unavailable<Value> = CommandLineToolInvocationSummary._Unavailable<Self, Value> where Value: CommandLineToolInvocationSummary.InvocationSummaryValue
    typealias Mode = CommandLineToolInvocationSummary.InvocationMode<Self>
    typealias Switch<Value> = CommandLineToolInvocationSummary.InvocationSummarySwitchCondition<Self, Value> where Value: CommandLineToolInvocationSummary.InvocationSummaryValue
    typealias Case = CommandLineToolInvocationSummary.Case<Self>
    typealias DefaultCase = CommandLineToolInvocationSummary.DefaultCase<Self>

    associatedtype SummaryContent: InvocationSummary

    @InvocationSummaryBuilder<Command>
    var invocationSummary: SummaryContent { get }
}

extension CommandLineTool where Self: _InvocationSummarySubcommandWithParentCommand {
    public typealias InvocationSummaryValueReferenceFromParent<Value> = CommandLineToolInvocationSummary.InvocationSummaryValueReferenceFromParent<ParentCommand, Self, Value> where Value: CommandLineToolInvocationSummary.InvocationSummaryValue
}

extension CommandLineTool {
    public var invocationSummary: some InvocationSummary {
        CommandLineToolInvocationSummary.DefaultInvocationSummary<Self>()
    }

    public func invocationArgumentValues(
        context: InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        CommandLineToolInvocation.Arguments(
            try invocationComponents(context: context).flatMap(\.argumentValues)
        )
    }

    public func invocationComponents(
        context: InvocationSummaryContext
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

    public func invocationArguments(context: InvocationSummaryContext) throws -> [String] {
        try invocationArgumentValues(context: context).rawValues
    }

    public func invocationSummaryComponents(
        for keyPaths: [PartialKeyPath<Self>],
        context: InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Components {
        return context.invocationComponents(
            for: keyPaths,
            command: self
        )
    }

    @discardableResult
    public func lowerInvocationSummary(
        context: InvocationSummaryContext
    ) throws -> InvocationSummaryContext {
        _ = try invocationComponents(context: context)

        return context
    }

    public func loweredInvocationSummaryComponents(
        for keyPaths: [PartialKeyPath<Self>],
        context: InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Components {
        try lowerInvocationSummary(context: context)

        return try invocationSummaryComponents(
            for: keyPaths,
            context: context
        )
    }

    public func loweredInvocationSummaryComponentGroups(
        for keyPathGroups: [[PartialKeyPath<Self>]],
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Components] {
        try lowerInvocationSummary(context: context)

        return try keyPathGroups.map {
            try invocationSummaryComponents(
                for: $0,
                context: context
            )
        }
    }

    public func identifiedInvocationSummaryComponents(
        for keyPaths: [PartialKeyPath<Self>],
        context: InvocationSummaryContext
    ) throws -> [_ResolvedCommandLineToolDescription.IdentifiedInvocationComponent] {
        return context.identifiedInvocationComponents(
            for: keyPaths,
            command: self
        )
    }

    public func invocationSummaryComponents(
        for keyPaths: [PartialKeyPath<Self>]
    ) throws -> CommandLineToolInvocation.Components {
        let context = InvocationSummaryContext()

        _ = try invocationComponents(context: context)

        return try invocationSummaryComponents(
            for: keyPaths,
            context: context
        )
    }

    public func identifiedInvocationSummaryComponents(
        for keyPaths: [PartialKeyPath<Self>]
    ) throws -> [_ResolvedCommandLineToolDescription.IdentifiedInvocationComponent] {
        let context = InvocationSummaryContext()

        _ = try invocationComponents(context: context)

        return try identifiedInvocationSummaryComponents(
            for: keyPaths,
            context: context
        )
    }

    public var invocation: String {
        get throws {
            try invocationArgumentValues(context: InvocationSummaryContext()).description
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
