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
            defaultPosition: resolved.defaultPosition,
            components: components
        )

        return shouldRender ? components : []
    }
}

/// Summary node that intentionally handles summary content without rendering it.
public struct Omit<Command: AnyCommandLineTool, Content>: InvocationSummary {
    let makeComponents: (Command, AnyCommandLineTool?, InvocationSummaryContext) throws -> [CommandLineToolInvocation.Component]

    init(
        _makeComponents makeComponents: @escaping (Command, AnyCommandLineTool?, InvocationSummaryContext) throws -> [CommandLineToolInvocation.Component]
    ) {
        self.makeComponents = makeComponents
    }

    public init(
        _ keyPath: KeyPath<Command, Content>,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil
    ) where Content: InvocationSummaryValue {
        let location = SourceCodeLocation(fileID: fileID, function: function, line: line, column: column)

        self.makeComponents = { command, _, context in
            try context.registerHandledValueReference(
                command: command,
                keyPath,
                disposition: .omitted,
                location: location
            )

            return []
        }
    }

    public init(
        keyPath: KeyPath<Command, Content>,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil
    ) where Content: InvocationSummaryValue {
        self.init(keyPath, fileID: fileID, function: function, line: line, column: column)
    }

    public init(
        unless condition: InvocationSummaryCondition<Command> = .never,
        reason: String? = nil,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil,
        @InvocationSummaryBuilder<Command> content: () -> Content
    ) where Content: InvocationSummary, Content.Command == Command {
        let content = content()
        let location = SourceCodeLocation(fileID: fileID, function: function, line: line, column: column)

        self.makeComponents = { command, parent, context in
            if try condition.evaluate(command: command, parent: parent, context: context) {
                return try content.makeInvocationComponents(
                    command: command,
                    parent: parent,
                    context: context
                )
            }

            guard let target = content as? any _InvocationSummaryApplicabilityTarget<Command> else {
                throw CommandLineToolInvocationSummary.Error.unsupportedInvocationSummaryModifierContent(
                    modifier: String(reflecting: Self.self),
                    content: Content.self,
                    location: location
                )
            }

            try target._registerArgumentApplicability(
                command: command,
                parent: parent,
                context: context,
                otherwise: .omit(reason: reason),
                location: location
            )

            return []
        }
    }

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        try makeComponents(command, parent, context)
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
                defaultPosition: resolved.defaultPosition,
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

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolInvocationSummary.InvocationSummaryValueReference: CommandLineToolInvocationSummary._InvocationSummaryApplicabilityTarget {
    public func _registerArgumentApplicability(
        command: Command,
        parent: AnyCommandLineTool?,
        context: CommandLineToolInvocationSummary.InvocationSummaryContext,
        otherwise: _CommandLineToolArgumentApplicability<Command>.Otherwise,
        location: SourceCodeLocation?
    ) throws {
        let argumentID = CommandLineToolInvocationSummary.InvocationSummaryContext.argumentID(command: command, keyPath: keyPath)
        let resolved = try command[keyPath: keyPath].resolve(
            in: .init(
                resolvingID: argumentID,
                defaultKeyConversion: command.keyConversion
            )
        )
        let components = resolved.publicInvocationComponents

        switch otherwise {
            case .omit(let reason):
                try context.registerHandledValueReference(
                    command: command,
                    keyPath,
                    disposition: .omitted,
                    reason: reason,
                    location: location
                )
            case .unavailable(let reason):
                try context.registerHandledValueReference(
                    command: command,
                    keyPath,
                    disposition: .unavailable,
                    defaultPosition: resolved.defaultPosition,
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
}
