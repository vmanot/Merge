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
/// A provisional hook for SwiftUI-style decorators around invocation summary content.
public protocol _InvocationSummaryModifier<Command> {
    associatedtype Command: AnyCommandLineTool

    func makeInvocationComponents(
        content: _InvocationSummaryModifierContent<Command>,
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component]
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Callable content passed into an invocation summary modifier.
public struct _InvocationSummaryModifierContent<Command: AnyCommandLineTool> {
    private let makeComponents: (Command, AnyCommandLineTool?, InvocationSummaryContext) throws -> [CommandLineToolInvocation.Component]
    private let registerApplicability: (Command, AnyCommandLineTool?, InvocationSummaryContext, _CommandLineToolArgumentApplicability<Command>.Otherwise, SourceCodeLocation?) throws -> Void

    public init<Content: InvocationSummary>(
        _ content: Content
    ) where Content.Command == Command {
        self.makeComponents = { command, parent, context in
            try content.makeInvocationComponents(
                command: command,
                parent: parent,
                context: context
            )
        }
        self.registerApplicability = { command, parent, context, otherwise, location in
            guard let target = content as? any _InvocationSummaryApplicabilityTarget<Command> else {
                throw CommandLineToolInvocationSummary.Error.unsupportedInvocationSummaryModifierContent(
                    modifier: String(reflecting: _CommandLineToolArgumentApplicability<Command>.self),
                    content: Content.self,
                    location: location
                )
            }

            try target._registerArgumentApplicability(
                command: command,
                parent: parent,
                context: context,
                otherwise: otherwise,
                location: location
            )
        }
    }

    public func makeInvocationComponents(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        try makeComponents(command, parent, context)
    }

    public func _registerArgumentApplicability(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext,
        otherwise: _CommandLineToolArgumentApplicability<Command>.Otherwise,
        location: SourceCodeLocation?
    ) throws {
        try registerApplicability(command, parent, context, otherwise, location)
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Summary node produced by applying a modifier to existing invocation summary content.
public struct _ModifiedInvocationSummary<Content: InvocationSummary, Modifier: _InvocationSummaryModifier>: InvocationSummary where Content.Command == Modifier.Command {
    public var content: Content
    public var modifier: Modifier

    public init(
        content: Content,
        modifier: Modifier
    ) {
        self.content = content
        self.modifier = modifier
    }

    public func makeInvocationComponents(
        command: Content.Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        try modifier.makeInvocationComponents(
            content: _InvocationSummaryModifierContent(content),
            command: command,
            parent: parent,
            context: context
        )
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Internal protocol for summary content that can register argument-level applicability dispositions.
public protocol _InvocationSummaryApplicabilityTarget<Command>: InvocationSummary {
    func _registerArgumentApplicability(
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext,
        otherwise: _CommandLineToolArgumentApplicability<Command>.Otherwise,
        location: SourceCodeLocation?
    ) throws
}
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolInvocationSummary.InvocationSummary {
    public func _modifier<Modifier: CommandLineToolInvocationSummary._InvocationSummaryModifier>(
        _ modifier: Modifier
    ) -> CommandLineToolInvocationSummary._ModifiedInvocationSummary<Self, Modifier> where Modifier.Command == Command {
        .init(content: self, modifier: modifier)
    }

    public func _applicable(
        when condition: CommandLineToolInvocationSummary.InvocationSummaryCondition<Command>,
        otherwise: _CommandLineToolArgumentApplicability<Command>.Otherwise,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil
    ) -> some CommandLineToolInvocationSummary.InvocationSummary {
        _modifier(
            CommandLineToolInvocationSummary._ArgumentApplicabilityModifier(
                applicability: .init(when: condition, otherwise: otherwise),
                location: SourceCodeLocation(fileID: fileID, function: function, line: line, column: column)
            )
        )
    }

    public func _unavailable(
        unless condition: CommandLineToolInvocationSummary.InvocationSummaryCondition<Command>,
        reason: String? = nil,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil
    ) -> some CommandLineToolInvocationSummary.InvocationSummary {
        _applicable(
            when: condition,
            otherwise: .unavailable(reason: reason),
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )
    }

    public func _omitted(
        unless condition: CommandLineToolInvocationSummary.InvocationSummaryCondition<Command>,
        reason: String? = nil,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil
    ) -> some CommandLineToolInvocationSummary.InvocationSummary {
        _applicable(
            when: condition,
            otherwise: .omit(reason: reason),
            fileID: fileID,
            function: function,
            line: line,
            column: column
        )
    }
}

extension CommandLineToolInvocationSummary {
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct _ArgumentApplicabilityModifier<Command: AnyCommandLineTool>: _InvocationSummaryModifier {
    public var applicability: _CommandLineToolArgumentApplicability<Command>
    public var location: SourceCodeLocation?

    public init(
        applicability: _CommandLineToolArgumentApplicability<Command>,
        location: SourceCodeLocation? = nil
    ) {
        self.applicability = applicability
        self.location = location
    }

    public func makeInvocationComponents(
        content: _InvocationSummaryModifierContent<Command>,
        command: Command,
        parent: AnyCommandLineTool?,
        context: InvocationSummaryContext
    ) throws -> [CommandLineToolInvocation.Component] {
        if try applicability.condition.evaluate(command: command, parent: parent, context: context) {
            return try content.makeInvocationComponents(
                command: command,
                parent: parent,
                context: context
            )
        }

        try content._registerArgumentApplicability(
            command: command,
            parent: parent,
            context: context,
            otherwise: applicability.otherwise,
            location: location
        )

        return []
    }
}
}
