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

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        let resolved = try command[keyPath: keyPath].resolve(
            in: .init(
                resolvingID: InvocationSummaryContext.argumentID(command: command, keyPath: keyPath),
                defaultKeyConversion: command.keyConversion
            )
        )
        let components = resolved.publicInvocationComponents
        let shouldRender = try context.registerHandledValueReference(
            command: command,
            keyPath,
            disposition: .explicitRender,
            components: components
        )

        return shouldRender ? components : []
    }
}

/// Summary node that intentionally handles a property-wrapper value without rendering it.
public struct Omit<Command: AnyCommandLineTool, Value: InvocationSummaryValue>: InvocationSummary {
    let register: (Command, AnyCommandLineTool?, InvocationSummaryContext) throws -> Void

    public init(
        _ keyPath: KeyPath<Command, Value>,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil
    ) {
        let location = SourceCodeLocation(fileID: fileID, function: function, line: line, column: column)

        self.register = { command, _, context in
            try context.registerHandledValueReference(
                command: command,
                keyPath,
                disposition: .omitted,
                location: location
            )
        }
    }

    public init(
        keyPath: KeyPath<Command, Value>,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil
    ) {
        self.init(keyPath, fileID: fileID, function: function, line: line, column: column)
    }

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        try register(command, parent, context)

        return []
    }
}

/// Summary node that rejects a property-wrapper value when it would render in this summary context.
public struct _Unavailable<Command: AnyCommandLineTool, Value: InvocationSummaryValue>: InvocationSummary {
    let validate: (Command, AnyCommandLineTool?, InvocationSummaryContext) throws -> Void

    public init(
        _ keyPath: KeyPath<Command, Value>,
        reason: String? = nil,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil
    ) {
        let location = SourceCodeLocation(fileID: fileID, function: function, line: line, column: column)

        self.validate = { command, _, context in
            let argumentID = InvocationSummaryContext.argumentID(command: command, keyPath: keyPath)
            let resolved = try command[keyPath: keyPath].resolve(
                in: .init(
                    resolvingID: argumentID,
                    defaultKeyConversion: command.keyConversion
                )
            )
            let components = resolved.publicInvocationComponents

            try context.registerHandledValueReference(
                command: command,
                keyPath,
                disposition: .unavailable,
                components: components,
                reason: reason,
                location: location
            )

            guard components.allSatisfy({ $0.argumentValues.isEmpty }) else {
                throw CommandLineToolInvocationSummary.Error.unsupportedArgument(
                    command: command.commandName,
                    argument: argumentID,
                    disposition: .unavailable,
                    components: components,
                    reason: reason,
                    location: location
                )
            }
        }
    }

    public init(
        keyPath: KeyPath<Command, Value>,
        reason: String? = nil,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil
    ) {
        self.init(keyPath, reason: reason, fileID: fileID, function: function, line: line, column: column)
    }

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        try validate(command, parent, context)

        return []
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
