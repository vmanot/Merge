#if os(macOS)
//
//  InvocationSummaryValue.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

extension CommandLineToolInvocationSummary {
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct InvocationSummaryValueReference<Command: AnyCommandLineTool, Value: InvocationSummaryValue>: InvocationSummary {
    let keyPath: KeyPath<Command, Value>

    public init(keyPath: KeyPath<Command, Value>) {
        self.keyPath = keyPath
    }

    public func makeInvocationArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [String] {
        guard !context.argumentIsRendered(command: command, keyPath) else {
            return []
        }
        defer { context.registerValueReference(command: command, keyPath) }

        let resolved = try command[keyPath: keyPath].resolve(
            in: .init(
                resolvingID: _ResolvedCommandLineToolDescription.ArgumentID(
                    rawValue: UUID().uuidString, // construct a temporary string.
                    commandName: command._commandName
                ),
                defaultKeyConversion: command.keyConversion
            )
        )

        if let argument = resolved.invocationArgument {
            return [argument]
        } else {
            return []
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol InvocationSummaryValue<WrappedValue>: PropertyWrapper, Resolvable where Result == _AnyResolvedCommandLineToolInvocationArgument, Context == _CommandLineToolResolutionContext {

}

}

#endif
