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
extension CommandLineToolInvocationSummary {
    public struct Case<Command: AnyCommandLineTool> {
        enum Kind {
            case mode(InvocationSummaryCondition<Command>)
            case switchValue(AnyEquatable)
        }

        let kind: Kind
        let content: any InvocationSummary<Command>
        let label: String
        let location: SourceCodeLocation?

        public init<Content: InvocationSummary>(
            condition: InvocationSummaryCondition<Command>,
            label: String? = nil,
            fileID: StaticString = #fileID,
            function: StaticString = #function,
            line: UInt = #line,
            column: UInt? = nil,
            @InvocationSummaryBuilder<Command> _ content: () -> Content
        ) where Content.Command == Command {
            self.kind = .mode(condition)
            self.content = content()
            self.label = label ?? String(describing: condition)
            self.location = SourceCodeLocation(fileID: fileID, function: function, line: line, column: column)
        }

        public init<Content: InvocationSummary>(
            _ condition: InvocationSummaryCondition<Command>,
            label: String? = nil,
            fileID: StaticString = #fileID,
            function: StaticString = #function,
            line: UInt = #line,
            column: UInt? = nil,
            @InvocationSummaryBuilder<Command> _ content: () -> Content
        ) where Content.Command == Command {
            self.init(
                condition: condition,
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
            _ predicate: InvocationSummaryValuePredicate<Value.WrappedValue>,
            label: String? = nil,
            fileID: StaticString = #fileID,
            function: StaticString = #function,
            line: UInt = #line,
            column: UInt? = nil,
            @InvocationSummaryBuilder<Command> _ content: () -> Content
        ) where Content.Command == Command {
            self.init(
                condition: .keyPath(value, predicate),
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

        public init<SwitchValue: Equatable, Content: InvocationSummary>(
            _ value: SwitchValue,
            @InvocationSummaryBuilder<Command> _ content: () -> Content
        ) where Content.Command == Command {
            self.kind = .switchValue(value.eraseToAnyEquatable())
            self.content = content()
            self.label = String(describing: value)
            self.location = nil
        }

        public init<SwitchValue: Equatable, Content: InvocationSummary>(
            value: SwitchValue,
            @InvocationSummaryBuilder<Command> _ content: () -> Content
        ) where Content.Command == Command {
            self.init(value, content)
        }

        func evaluateModeCondition(
            command: Command,
            parent: AnyCommandLineTool?,
            context: InvocationSummaryContext
        ) throws -> Bool {
            switch kind {
                case .mode(let condition):
                    return try condition.evaluate(command: command, parent: parent, context: context)
                case .switchValue:
                    return false
            }
        }

        func matchesSwitchValue<Value: InvocationSummaryValue>(
            _ value: Value
        ) -> Bool {
            switch kind {
                case .mode:
                    return false
                case .switchValue(let expected):
                    if (try? AnyEquatable(from: value.wrappedValue)) == expected {
                        return true
                    }

                    return (try? AnyEquatable(from: _unwrapPossiblyOptionalAny(value.wrappedValue))) == expected
            }
        }

        @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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
    }

    public struct DefaultCase<Command: AnyCommandLineTool> {
        let content: any InvocationSummary<Command>

        public init<Content: InvocationSummary>(
            @InvocationSummaryBuilder<Command> _ content: () -> Content
        ) where Content.Command == Command {
            self.content = content()
        }

        @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
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
    }

    public struct CaseList<Command: AnyCommandLineTool> {
        var cases: [Case<Command>]
        var defaultCase: DefaultCase<Command>?
    }

    @resultBuilder
    public struct CaseBuilder<Command: AnyCommandLineTool> {
        public static func buildExpression(
            _ expression: Case<Command>
        ) -> CaseList<Command> {
            CaseList(cases: [expression], defaultCase: nil)
        }

        public static func buildExpression(
            _ expression: DefaultCase<Command>
        ) -> CaseList<Command> {
            CaseList(cases: [], defaultCase: expression)
        }

        public static func buildBlock(
            _ content: CaseList<Command>...
        ) -> CaseList<Command> {
            var cases: [Case<Command>] = []
            var defaultCase: DefaultCase<Command>?

            for item in content {
                cases.append(contentsOf: item.cases)

                if let itemDefault = item.defaultCase {
                    defaultCase = itemDefault
                }
            }

            return CaseList(cases: cases, defaultCase: defaultCase)
        }
    }

    public struct InvocationSummarySwitchCondition<Command: AnyCommandLineTool, Value: InvocationSummaryValue>: InvocationSummary {
        private let keyPath: KeyPath<Command, Value>
        private let cases: [Case<Command>]
        private let defaultCase: DefaultCase<Command>?
        private let location: SourceCodeLocation

        public init(
            _ value: KeyPath<Command, Value>,
            fileID: StaticString = #fileID,
            function: StaticString = #function,
            line: UInt = #line,
            column: UInt? = nil,
            @CaseBuilder<Command> _ content: () -> CaseList<Command>
        ) {
            let content = content()

            self.keyPath = value
            self.cases = content.cases
            self.defaultCase = content.defaultCase
            self.location = SourceCodeLocation(fileID: fileID, function: function, line: line, column: column)
        }

        @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
        public func makeInvocationArguments(
            command: Command,
            parent: AnyCommandLineTool?,
            context: InvocationSummaryContext
        ) throws -> CommandLineToolInvocation.Arguments {
            CommandLineToolInvocation.Arguments(
                try makeInvocationComponents(
                    command: command,
                    parent: parent,
                    context: context
                )
                .flatMap(\.argumentValues)
            )
        }

        @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
        public func makeInvocationComponents(
            command: Command,
            parent: AnyCommandLineTool?,
            context: InvocationSummaryContext
        ) throws -> [CommandLineToolInvocation.Component] {
            let sourceValue = command[keyPath: keyPath]

            if let matchingCase = cases.first(where: { $0.matchesSwitchValue(sourceValue) }) {
                return try matchingCase.makeInvocationComponents(
                    command: command,
                    parent: parent,
                    context: context
                )
            }

            if let defaultCase {
                return try defaultCase.makeInvocationComponents(
                    command: command,
                    parent: parent,
                    context: context
                )
            } else {
                throw CommandLineToolInvocationSummary.Error.noSwitchCaseMatched(
                    command: command.commandName,
                    argument: InvocationSummaryContext.argumentID(command: command, keyPath: keyPath),
                    valueDescription: String(describing: sourceValue.wrappedValue),
                    location: location
                )
            }
        }
    }
}
