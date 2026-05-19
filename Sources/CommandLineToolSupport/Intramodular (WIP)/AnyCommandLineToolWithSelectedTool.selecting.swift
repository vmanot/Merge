//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation

extension CommandLineTool where Self: AnyCommandLineToolWithSelectedTool {
    public func selecting<Tool>(
        _ tool: Tool,
        name: String? = nil
    ) -> GenericSelectedCommandLineTool<Self, Tool> where Tool: AnyCommandLineTool & CommandLineTool {
        GenericSelectedCommandLineTool(
            selectingTool: self,
            selectedTool: tool,
            selectedToolCommandName: name
        )
    }
}

#endif
