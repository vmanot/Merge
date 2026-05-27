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
public struct InvocationMode<Command: AnyCommandLineTool>: InvocationSummary {
    let cases: [InvocationModeCase<Command>]
    let defaultCase: InvocationModeDefaultCase<Command>?
    let location: SourceCodeLocation?

    public init(
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil,
        @InvocationModeCaseBuilder<Command> _ content: () -> InvocationModeCaseList<Command>
    ) {
        let content = content()

        self.cases = content.cases
        self.defaultCase = content.defaultCase
        self.location = SourceCodeLocation(fileID: fileID, function: function, line: line, column: column)
    }

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        var matchedCases: [(offset: Int, element: InvocationModeCase<Command>)] = []

        for (offset, invocationCase) in cases.enumerated() {
            if try invocationCase.condition.evaluate(command: command, parent: parent, context: context) {
                matchedCases.append((offset, invocationCase))
            }
        }

        guard matchedCases.count <= 1 else {
            let first = matchedCases[0].element
            let second = matchedCases[1].element

            throw Error.conflictingInvocationModes(
                command: command.commandName,
                first: first.label,
                second: second.label,
                location: second.location ?? first.location ?? location
            )
        }

        if let matchedCase = matchedCases.first {
            let components = try matchedCase.element.makeInvocationComponents(
                command: command,
                parent: parent,
                context: context
            )

            for (offset, invocationCase) in cases.enumerated() where offset != matchedCase.offset {
                try invocationCase.registerInactiveIgnoringSelectedArguments(
                    command: command,
                    parent: parent,
                    context: context
                )
            }

            try defaultCase?.registerInactiveIgnoringSelectedArguments(
                command: command,
                parent: parent,
                context: context
            )

            return components
        }

        for invocationCase in cases {
            try invocationCase.registerInactive(
                command: command,
                parent: parent,
                context: context
            )
        }

        return try defaultCase?.makeInvocationComponents(
            command: command,
            parent: parent,
            context: context
        ) ?? []
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct InvocationModeCase<Command: AnyCommandLineTool> {
    let condition: InvocationSummaryCondition<Command>
    let content: any InvocationSummary<Command>
    let label: String
    let location: SourceCodeLocation?

    public init<Content: InvocationSummary>(
        _ condition: InvocationSummaryCondition<Command>,
        label: String? = nil,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil,
        @InvocationSummaryBuilder<Command> _ content: () -> Content
    ) where Content.Command == Command {
        self.condition = condition
        self.content = content()
        self.label = label ?? String(describing: condition)
        self.location = SourceCodeLocation(fileID: fileID, function: function, line: line, column: column)
    }

    public init<Value: InvocationSummaryValue, Content: InvocationSummary>(
        _ value: KeyPath<Command, Value>,
        _ predicate: InvocationSummaryValuePredicate<Value.WrappedValue>,
        label: String? = nil,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil,
        @InvocationSummaryBuilder<Command> _ content: () -> Content
    ) where Content.Command == Command {
        self.init(
            .keyPath(value, predicate),
            label: label,
            fileID: fileID,
            function: function,
            line: line,
            column: column,
            content
        )
    }

    public init<Value: InvocationSummaryValue, Content: InvocationSummary>(
        _ value: KeyPath<Command, Value>,
        equals expected: Value.WrappedValue,
        label: String? = nil,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil,
        @InvocationSummaryBuilder<Command> _ content: () -> Content
    ) where Value.WrappedValue: Equatable, Content.Command == Command {
        self.init(
            value,
            .equals(expected),
            label: label,
            fileID: fileID,
            function: function,
            line: line,
            column: column,
            content
        )
    }

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        try content.makeInvocationComponents(
            command: command,
            parent: parent,
            context: context
        )
    }

    func registerInactive(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws {
        guard let target = content as? any _InvocationSummaryApplicabilityTarget<Command> else {
            throw Error.unsupportedInvocationSummaryModifierContent(
                modifier: String(reflecting: InvocationMode.self),
                content: Swift.type(of: content),
                location: location
            )
        }

        try target._registerArgumentApplicability(
            command: command,
            parent: parent,
            context: context,
            otherwise: .omit(reason: "argument belongs to an inactive invocation mode"),
            location: location
        )
    }

    func registerInactiveIgnoringSelectedArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws {
        do {
            try registerInactive(
                command: command,
                parent: parent,
                context: context
            )
        } catch let error as Error {
            guard case .conflictingArgumentDisposition(_, _, let existing, let new, _) = error else {
                throw error
            }

            guard existing.disposition == .explicitRender, new.disposition == .omitted else {
                throw error
            }
        } catch {
            throw error
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct InvocationModeDefaultCase<Command: AnyCommandLineTool> {
    let content: any InvocationSummary<Command>

    public init<Content: InvocationSummary>(
        @InvocationSummaryBuilder<Command> _ content: () -> Content
    ) where Content.Command == Command {
        self.content = content()
    }

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        try content.makeInvocationComponents(
            command: command,
            parent: parent,
            context: context
        )
    }

    func registerInactive(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws {
        guard let target = content as? any _InvocationSummaryApplicabilityTarget<Command> else {
            throw Error.unsupportedInvocationSummaryModifierContent(
                modifier: String(reflecting: InvocationMode.self),
                content: Swift.type(of: content),
                location: nil
            )
        }

        try target._registerArgumentApplicability(
            command: command,
            parent: parent,
            context: context,
            otherwise: .omit(reason: "argument belongs to an inactive invocation mode"),
            location: nil
        )
    }

    func registerInactiveIgnoringSelectedArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws {
        do {
            try registerInactive(
                command: command,
                parent: parent,
                context: context
            )
        } catch let error as Error {
            guard case .conflictingArgumentDisposition(_, _, let existing, let new, _) = error else {
                throw error
            }

            guard existing.disposition == .explicitRender, new.disposition == .omitted else {
                throw error
            }
        } catch {
            throw error
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct InvocationModeCaseList<Command: AnyCommandLineTool> {
    public var cases: [InvocationModeCase<Command>]
    public var defaultCase: InvocationModeDefaultCase<Command>?
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@resultBuilder
public enum InvocationModeCaseBuilder<Command: AnyCommandLineTool> {
    public static func buildExpression(
        _ expression: InvocationModeCase<Command>
    ) -> InvocationModeCaseList<Command> {
        InvocationModeCaseList(cases: [expression], defaultCase: nil)
    }

    public static func buildExpression(
        _ expression: InvocationModeDefaultCase<Command>
    ) -> InvocationModeCaseList<Command> {
        InvocationModeCaseList(cases: [], defaultCase: expression)
    }

    public static func buildBlock(
        _ content: InvocationModeCaseList<Command>...
    ) -> InvocationModeCaseList<Command> {
        var cases: [InvocationModeCase<Command>] = []
        var defaultCase: InvocationModeDefaultCase<Command>?

        for item in content {
            cases.append(contentsOf: item.cases)

            if let itemDefault = item.defaultCase {
                defaultCase = itemDefault
            }
        }

        return InvocationModeCaseList(cases: cases, defaultCase: defaultCase)
    }
}

}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public func Mode<Command: AnyCommandLineTool>(
    fileID: StaticString = #fileID,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt? = nil,
    @CommandLineToolInvocationSummary.InvocationModeCaseBuilder<Command> _ content: () -> CommandLineToolInvocationSummary.InvocationModeCaseList<Command>
) -> CommandLineToolInvocationSummary.InvocationMode<Command> {
    CommandLineToolInvocationSummary.InvocationMode(
        fileID: fileID,
        function: function,
        line: line,
        column: column,
        content
    )
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public func Case<Command: AnyCommandLineTool, Content: CommandLineToolInvocationSummary.InvocationSummary>(
    _ condition: CommandLineToolInvocationSummary.InvocationSummaryCondition<Command>,
    label: String? = nil,
    fileID: StaticString = #fileID,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt? = nil,
    @CommandLineToolInvocationSummary.InvocationSummaryBuilder<Command> _ content: () -> Content
) -> CommandLineToolInvocationSummary.InvocationModeCase<Command> where Content.Command == Command {
    CommandLineToolInvocationSummary.InvocationModeCase(
        condition,
        label: label,
        fileID: fileID,
        function: function,
        line: line,
        column: column,
        content
    )
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public func ModeCase<Command: AnyCommandLineTool, Content: CommandLineToolInvocationSummary.InvocationSummary>(
    _ condition: CommandLineToolInvocationSummary.InvocationSummaryCondition<Command>,
    label: String? = nil,
    fileID: StaticString = #fileID,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt? = nil,
    @CommandLineToolInvocationSummary.InvocationSummaryBuilder<Command> _ content: () -> Content
) -> CommandLineToolInvocationSummary.InvocationModeCase<Command> where Content.Command == Command {
    Case(
        condition,
        label: label,
        fileID: fileID,
        function: function,
        line: line,
        column: column,
        content
    )
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public func Case<Command: AnyCommandLineTool, Value: CommandLineToolInvocationSummary.InvocationSummaryValue, Content: CommandLineToolInvocationSummary.InvocationSummary>(
    _ value: KeyPath<Command, Value>,
    _ predicate: CommandLineToolInvocationSummary.InvocationSummaryValuePredicate<Value.WrappedValue>,
    label: String? = nil,
    fileID: StaticString = #fileID,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt? = nil,
    @CommandLineToolInvocationSummary.InvocationSummaryBuilder<Command> _ content: () -> Content
) -> CommandLineToolInvocationSummary.InvocationModeCase<Command> where Content.Command == Command {
    Case(
        .keyPath(value, predicate),
        label: label,
        fileID: fileID,
        function: function,
        line: line,
        column: column,
        content
    )
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public func ModeCase<Command: AnyCommandLineTool, Value: CommandLineToolInvocationSummary.InvocationSummaryValue, Content: CommandLineToolInvocationSummary.InvocationSummary>(
    _ value: KeyPath<Command, Value>,
    _ predicate: CommandLineToolInvocationSummary.InvocationSummaryValuePredicate<Value.WrappedValue>,
    label: String? = nil,
    fileID: StaticString = #fileID,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt? = nil,
    @CommandLineToolInvocationSummary.InvocationSummaryBuilder<Command> _ content: () -> Content
) -> CommandLineToolInvocationSummary.InvocationModeCase<Command> where Content.Command == Command {
    Case(
        value,
        predicate,
        label: label,
        fileID: fileID,
        function: function,
        line: line,
        column: column,
        content
    )
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public func Case<Command: AnyCommandLineTool, Value: CommandLineToolInvocationSummary.InvocationSummaryValue, Content: CommandLineToolInvocationSummary.InvocationSummary>(
    _ value: KeyPath<Command, Value>,
    equals expected: Value.WrappedValue,
    label: String? = nil,
    fileID: StaticString = #fileID,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt? = nil,
    @CommandLineToolInvocationSummary.InvocationSummaryBuilder<Command> _ content: () -> Content
) -> CommandLineToolInvocationSummary.InvocationModeCase<Command> where Value.WrappedValue: Equatable, Content.Command == Command {
    Case(
        value,
        .equals(expected),
        label: label,
        fileID: fileID,
        function: function,
        line: line,
        column: column,
        content
    )
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public func ModeCase<Command: AnyCommandLineTool, Value: CommandLineToolInvocationSummary.InvocationSummaryValue, Content: CommandLineToolInvocationSummary.InvocationSummary>(
    _ value: KeyPath<Command, Value>,
    equals expected: Value.WrappedValue,
    label: String? = nil,
    fileID: StaticString = #fileID,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt? = nil,
    @CommandLineToolInvocationSummary.InvocationSummaryBuilder<Command> _ content: () -> Content
) -> CommandLineToolInvocationSummary.InvocationModeCase<Command> where Value.WrappedValue: Equatable, Content.Command == Command {
    Case(
        value,
        equals: expected,
        label: label,
        fileID: fileID,
        function: function,
        line: line,
        column: column,
        content
    )
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public func Default<Command: AnyCommandLineTool, Content: CommandLineToolInvocationSummary.InvocationSummary>(
    @CommandLineToolInvocationSummary.InvocationSummaryBuilder<Command> _ content: () -> Content
) -> CommandLineToolInvocationSummary.InvocationModeDefaultCase<Command> where Content.Command == Command {
    CommandLineToolInvocationSummary.InvocationModeDefaultCase(content)
}
