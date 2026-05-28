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
    let cases: [Case<Command>]
    let defaultCase: DefaultCase<Command>?
    let location: SourceCodeLocation?

    public init(
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt? = nil,
        @CaseBuilder<Command> _ content: () -> CaseList<Command>
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
        var matchedCases: [(offset: Int, element: Case<Command>)] = []

        for (offset, invocationCase) in cases.enumerated() {
            if try invocationCase.evaluateModeCondition(command: command, parent: parent, context: context) {
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
                try invocationCase.registerInactiveInvocationModeCaseIgnoringSelectedArguments(
                    command: command,
                    parent: parent,
                    context: context
                )
            }

            try defaultCase?.registerInactiveInvocationModeCaseIgnoringSelectedArguments(
                command: command,
                parent: parent,
                context: context
            )

            return components
        }

        for invocationCase in cases {
            try invocationCase.registerInactiveInvocationModeCase(
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

}

extension CommandLineToolInvocationSummary.Case {
    func registerInactiveInvocationModeCase(
        command: Command,
        parent: AnyCommandLineTool?,
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws {
        try _registerInactiveInvocationModeContent(
            content,
            command: command,
            parent: parent,
            context: context,
            location: location
        )
    }

    func registerInactiveInvocationModeCaseIgnoringSelectedArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws {
        do {
            try registerInactiveInvocationModeCase(
                command: command,
                parent: parent,
                context: context
            )
        } catch let error as CommandLineToolInvocationSummary.Error {
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

extension CommandLineToolInvocationSummary.DefaultCase {
    func registerInactiveInvocationModeCase(
        command: Command,
        parent: AnyCommandLineTool?,
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws {
        try _registerInactiveInvocationModeContent(
            content,
            command: command,
            parent: parent,
            context: context,
            location: nil
        )
    }

    func registerInactiveInvocationModeCaseIgnoringSelectedArguments(
        command: Command,
        parent: AnyCommandLineTool?,
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws {
        do {
            try registerInactiveInvocationModeCase(
                command: command,
                parent: parent,
                context: context
            )
        } catch let error as CommandLineToolInvocationSummary.Error {
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

private func _registerInactiveInvocationModeContent<Command: AnyCommandLineTool>(
    _ content: any CommandLineToolInvocationSummary.InvocationSummary<Command>,
    command: Command,
    parent: AnyCommandLineTool?,
    context: CommandLineToolInvocationSummary.InvocationSummaryContext,
    location: SourceCodeLocation?
) throws {
    guard let target = content as? any CommandLineToolInvocationSummary._InvocationSummaryApplicabilityTarget<Command> else {
        throw CommandLineToolInvocationSummary.Error.unsupportedInvocationSummaryModifierContent(
            modifier: String(reflecting: CommandLineToolInvocationSummary.InvocationMode<Command>.self),
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
