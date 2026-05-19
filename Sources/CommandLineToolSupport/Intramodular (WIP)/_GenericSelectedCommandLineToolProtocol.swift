#if os(macOS)
//
//  _GenericSelectedCommandLineToolProtocol.swift
//  Merge
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Erasure hook used by rendering and execution records to inspect selected-tool wrappers generically.
public protocol _GenericSelectedCommandLineToolProtocol {
    associatedtype SelectingTool: AnyCommandLineToolWithSelectedTool & CommandLineTool
    var selectingTool: SelectingTool { get }

    associatedtype SelectedTool: AnyCommandLineTool & CommandLineTool
    var selectedTool: SelectedTool { get }
    var selectedToolCommandName: String { get }
}

extension _GenericSelectedCommandLineToolProtocol {
    var _opaqueSelectingTool: AnyCommandLineTool {
        selectingTool
    }

    var _opaqueSelectedTool: AnyCommandLineTool {
        selectedTool
    }

    var _opaqueSelectedToolCommandName: String {
        selectedToolCommandName
    }
}

#endif
