//
//  AnyCommandLineToolWithSelectedTool.swift
//  Merge
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
open class AnyCommandLineToolWithSelectedTool: AnyCommandLineTool {
    open var toolSelectionSemantics: ToolSelectionSemantics {
        .staticExplicitArgument
    }

    open var selectedToolResolutionSemantics: SelectedToolResolutionSemantics {
        .resolvesBeforeInvocationAndInvokesThroughSelectingTool
    }
}

