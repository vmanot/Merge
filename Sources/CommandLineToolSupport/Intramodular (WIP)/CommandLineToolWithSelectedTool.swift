#if os(macOS)
//
//  CommandLineToolWithSelectedTool.swift
//  Merge
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// A modeled command line tool value whose rendered command path includes a tool selected by another tool.
public protocol CommandLineToolWithSelectedTool: CommandLineTool {
    associatedtype SelectingTool: AnyCommandLineToolWithSelectedTool & CommandLineTool
    associatedtype SelectedCommandLineTool: AnyCommandLineTool & CommandLineTool

    var selectingTool: SelectingTool { get }
    var selectedTool: SelectedCommandLineTool { get }
    var toolSelectionSemantics: AnyCommandLineToolWithSelectedTool.ToolSelectionSemantics { get }
}

extension CommandLineToolWithSelectedTool {
    public var toolSelectionSemantics: AnyCommandLineToolWithSelectedTool.ToolSelectionSemantics {
        selectingTool.toolSelectionSemantics
    }
}

#endif
