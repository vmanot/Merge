//
// Copyright (c) Vatsal Manot
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct _CommandLineToolCommandChain: RandomAccessCollection, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    typealias Element = AnyCommandLineTool
    typealias Index = Array<AnyCommandLineTool>.Index

    var elements: [AnyCommandLineTool]

    init(_ elements: [AnyCommandLineTool]) {
        self.elements = elements
    }

    init?(
        resolving command: any CommandLineTool
    ) {
        if let selectedTool = command as? any _GenericSelectedCommandLineToolProtocol {
            self.init([
                selectedTool._opaqueSelectingTool,
                command
            ])
            return
        }

        guard let subcommand = command as? any _GenericSubcommandProtocol else {
            return nil
        }

        var result: [AnyCommandLineTool] = [command]
        var parent = subcommand._opaqueParent

        while true {
            if let parentSubcommand = parent as? any _GenericSubcommandProtocol {
                guard let parentSubcommandWrapper = parentSubcommand as? AnyCommandLineTool else {
                    preconditionFailure("Unable to resolve parent subcommand wrapper for \(type(of: parentSubcommand))")
                }

                result.insert(parentSubcommandWrapper, at: 0)
                parent = parentSubcommand._opaqueParent
            } else if let selectedTool = parent as? any _GenericSelectedCommandLineToolProtocol {
                guard let selectedToolWrapper = selectedTool as? AnyCommandLineTool else {
                    preconditionFailure("Unable to resolve selected tool wrapper for \(type(of: selectedTool))")
                }

                result.insert(selectedToolWrapper, at: 0)
                parent = selectedTool._opaqueSelectingTool
            } else {
                break
            }
        }

        result.insert(parent, at: 0)

        self.init(result)
    }

    init(
        resolvingOrSelf command: any CommandLineTool
    ) {
        self = Self(resolving: command) ?? Self([command])
    }

    var startIndex: Index {
        elements.startIndex
    }

    var endIndex: Index {
        elements.endIndex
    }

    subscript(position: Index) -> Element {
        elements[position]
    }

    var description: String {
        elements.map { $0.commandName?.rawValue ?? String(reflecting: type(of: $0)) }.joined(separator: " ")
    }

    var debugDescription: String {
        "_CommandLineToolCommandChain(\(elements.map { String(reflecting: type(of: $0)) }))"
    }

    var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "elements": elements
            ],
            displayStyle: .struct
        )
    }

    var attachedHostTool: (selectedTool: AnyCommandLineTool, hostTool: AnyCommandLineTool._AttachedToolHost)? {
        lazy.compactMap { tool in
            tool._attachedHostTool.map { (tool, $0) }
        }.first
    }

    func selectedToolInvocation(
        renderedInvocation: CommandLineToolInvocation
    ) -> _CommandLineToolSelectedToolInvocation? {
        if
            let selectingToolIndex = firstIndex(where: { $0 is AnyCommandLineToolWithSelectedTool }),
            indices.contains(selectingToolIndex + 1),
            let selectingTool = self[selectingToolIndex] as? AnyCommandLineToolWithSelectedTool
        {
            let selectedToolCommandPath = self[(selectingToolIndex + 1)...]
                .map { $0.requireCommandName().rawValue }

            guard let selectedToolCommandName = selectedToolCommandPath.first else {
                return nil
            }

            return _CommandLineToolSelectedToolInvocation(
                renderedInvocation: renderedInvocation,
                selectingToolCommandName: selectingTool.requireCommandName().rawValue,
                selectedToolCommandName: selectedToolCommandName,
                selectedToolCommandPath: selectedToolCommandPath,
                selectionSemantics: selectingTool.toolSelectionSemantics,
                resolutionSemantics: selectingTool.selectedToolResolutionSemantics
            )
        }

        if let selectedToolInvocation = attachedHostToolSelectedToolInvocation(renderedInvocation: renderedInvocation) {
            return selectedToolInvocation
        }

        return nil
    }

    func attachedHostToolSelectedToolInvocation(
        renderedInvocation: CommandLineToolInvocation
    ) -> _CommandLineToolSelectedToolInvocation? {
        guard
            let selectedToolIndex = firstIndex(where: { $0._attachedHostTool != nil }),
            let hostTool = self[selectedToolIndex]._attachedHostTool
        else {
            return nil
        }

        let selectedToolCommandPath = self[selectedToolIndex...].enumerated().map { offset, command in
            if offset == 0 {
                return hostTool._selectedToolCommandNameOverride ?? command.requireCommandName().rawValue
            } else {
                return command.requireCommandName().rawValue
            }
        }

        guard let selectedToolCommandName = selectedToolCommandPath.first else {
            return nil
        }

        let selectingTool = hostTool._selectingTool

        return _CommandLineToolSelectedToolInvocation(
            renderedInvocation: renderedInvocation,
            selectingToolCommandName: selectingTool.requireCommandName().rawValue,
            selectedToolCommandName: selectedToolCommandName,
            selectedToolCommandPath: selectedToolCommandPath,
            selectionSemantics: selectingTool.toolSelectionSemantics,
            resolutionSemantics: selectingTool.selectedToolResolutionSemantics
        )
    }

    func applyingAttachedHostToolIfNeeded(
        to arguments: CommandLineToolInvocation.Arguments,
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        try applyingAttachedHostToolIfNeeded(
            to: CommandLineToolInvocation.Components(arguments: arguments),
            context: context
        )
        .arguments
    }

    func applyingAttachedHostToolIfNeeded(
        to components: CommandLineToolInvocation.Components,
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Components {
        guard let (selectedTool, hostTool) = attachedHostTool else {
            return components
        }

        return try hostTool._invocationComponents(
            hosting: components,
            selectedTool: selectedTool,
            context: context
        )
    }

    static func sanitizingInvocationArguments(
        _ arguments: CommandLineToolInvocation.Arguments
    ) -> CommandLineToolInvocation.Arguments {
        CommandLineToolInvocation.Arguments(
            arguments.elements.filter { !$0.rawValue.isEmpty }
        )
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineTool {
    typealias CommandChain = _CommandLineToolCommandChain
}
