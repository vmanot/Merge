//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct _CommandLineToolArgumentApplicability<Command: AnyCommandLineTool> {
    public enum Otherwise: Hashable, Sendable {
        case omit(reason: String?)
        case unavailable(reason: String?)
    }
    
    public var condition: CommandLineToolInvocationSummary.InvocationSummaryCondition<Command>
    public var otherwise: Otherwise
    
    public init(
        when condition: CommandLineToolInvocationSummary.InvocationSummaryCondition<Command>,
        otherwise: Otherwise
    ) {
        self.condition = condition
        self.otherwise = otherwise
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
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
    
    /// Callable content passed into an invocation summary modifier.
    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct _InvocationSummaryModifierContent<Command: AnyCommandLineTool> {
        private let makeComponents: (Command, AnyCommandLineTool?, InvocationSummaryContext) throws -> [CommandLineToolInvocation.Component]
        private let registerApplicability: (Command, AnyCommandLineTool?, InvocationSummaryContext, _CommandLineToolArgumentApplicability<Command>.Otherwise, SourceCodeLocation?) throws -> Void
        
        @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
        public init<Content: InvocationSummary>(
            _ content: Content
        ) where Content.Command == Command {
#if os(macOS) || targetEnvironment(macCatalyst)
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
#else
            fatalError(.unavailable)
#endif
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
    
    /// Summary node produced by applying a modifier to existing invocation summary content.
    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
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
        
        @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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
    
    /// Internal protocol for summary content that can register argument-level applicability dispositions.
    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public protocol _InvocationSummaryApplicabilityTarget<Command>: InvocationSummary {
        @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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
    ) -> some CommandLineToolInvocationSummary.InvocationSummary<Command> {
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
    ) -> some CommandLineToolInvocationSummary.InvocationSummary<Command> {
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
    ) -> some CommandLineToolInvocationSummary.InvocationSummary<Command> {
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

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
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
