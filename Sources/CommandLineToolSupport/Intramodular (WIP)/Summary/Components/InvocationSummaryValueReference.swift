//
// Copyright (c) Vatsal Manot
//


import Foundation
import Swallow

extension CommandLineToolInvocationSummary {
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Summary node that renders one property-wrapper value from the current command.
public struct InvocationSummaryValueReference<Command: AnyCommandLineTool, Value: InvocationSummaryValue>: InvocationSummary {
    let keyPath: KeyPath<Command, Value>

    public init(keyPath: KeyPath<Command, Value>) {
        self.keyPath = keyPath
    }

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        guard !context.argumentIsRendered(command: command, keyPath) else {
            return []
        }
        defer { context.registerValueReference(command: command, keyPath) }

        let resolved = try command[keyPath: keyPath].resolve(
            in: .init(
                resolvingID: _ResolvedCommandLineToolDescription.ArgumentID(
                    rawValue: InvocationSummaryContext.argumentName(for: keyPath),
                    commandName: command.requireCommandName().rawValue
                ),
                defaultKeyConversion: command.keyConversion
            )
        )

        return CommandLineToolInvocation.Arguments(resolved.invocationArgumentValues)
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Property-wrapper requirement for values that can be referenced and rendered by an invocation summary.
public protocol InvocationSummaryValue<WrappedValue>: PropertyWrapper {
    associatedtype WrappedValue

    func resolve(
        in context: _CommandLineToolResolutionContext
    ) throws -> _AnyResolvedCommandLineToolInvocationArgument

}

}
