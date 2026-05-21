//
//  CommandLineToolThatResolvesAndInvokesSelectedTool.swift
//  Merge
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Refines selected-tool modeling for tools like `xcrun` that both resolve and invoke the selected tool.
public protocol CommandLineToolThatResolvesAndInvokesSelectedTool: CommandLineToolWithSelectedTool {
    var selectedToolResolutionSemantics: AnyCommandLineToolWithSelectedTool.SelectedToolResolutionSemantics { get }
}

extension CommandLineToolThatResolvesAndInvokesSelectedTool {
    public var selectedToolResolutionSemantics: AnyCommandLineToolWithSelectedTool.SelectedToolResolutionSemantics {
        selectingTool.selectedToolResolutionSemantics
    }
}

