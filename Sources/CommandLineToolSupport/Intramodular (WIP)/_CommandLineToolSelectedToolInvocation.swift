//
// Copyright (c) Vatsal Manot
//


import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Sidecar metadata describing the selected-tool portion of an execution record without changing its source shape.
public struct _CommandLineToolSelectedToolInvocation: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
    public var renderedInvocation: CommandLineToolInvocation
    public var selectingToolCommandName: String
    public var selectedToolCommandName: String
    public var selectedToolCommandPath: [String]
    public var selectionSemantics: AnyCommandLineToolWithSelectedTool.ToolSelectionSemantics
    public var resolutionSemantics: AnyCommandLineToolWithSelectedTool.SelectedToolResolutionSemantics

    public init(
        renderedInvocation: CommandLineToolInvocation,
        selectingToolCommandName: String,
        selectedToolCommandName: String,
        selectedToolCommandPath: [String],
        selectionSemantics: AnyCommandLineToolWithSelectedTool.ToolSelectionSemantics,
        resolutionSemantics: AnyCommandLineToolWithSelectedTool.SelectedToolResolutionSemantics
    ) {
        self.renderedInvocation = renderedInvocation
        self.selectingToolCommandName = selectingToolCommandName
        self.selectedToolCommandName = selectedToolCommandName
        self.selectedToolCommandPath = selectedToolCommandPath
        self.selectionSemantics = selectionSemantics
        self.resolutionSemantics = resolutionSemantics
    }
}

extension _CommandLineToolSelectedToolInvocation {
    public var description: String {
        commandLine
    }

    public var debugDescription: String {
        "_CommandLineToolSelectedToolInvocation(selectingToolCommandName: \(String(reflecting: selectingToolCommandName)), selectedToolCommandName: \(String(reflecting: selectedToolCommandName)), selectedToolCommandPath: \(selectedToolCommandPath), commandLine: \(String(reflecting: commandLine)))"
    }

    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "renderedInvocation": renderedInvocation,
                "selectingToolCommandName": selectingToolCommandName,
                "selectedToolCommandName": selectedToolCommandName,
                "selectedToolCommandPath": selectedToolCommandPath,
                "selectionSemantics": selectionSemantics,
                "resolutionSemantics": resolutionSemantics,
                "commandLine": commandLine
            ],
            displayStyle: .struct
        )
    }

    public var commandLine: String {
        renderedInvocation.commandLine
    }
}

