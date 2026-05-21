//
// Copyright (c) Vatsal Manot
//


import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineTool {
    public typealias SelectedTool = _CommandLineToolSelectedTool
}

@propertyWrapper
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Property wrapper for known selected-tool affordances exposed directly by a selecting tool.
public struct _CommandLineToolSelectedTool<SelectingTool, SelectedTool>: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable where SelectingTool: AnyCommandLineToolWithSelectedTool & CommandLineTool, SelectedTool: AnyCommandLineTool & CommandLineTool {
    public var name: String
    public var tool: SelectedTool

    public typealias WrappedValue = GenericSelectedCommandLineTool<SelectingTool, SelectedTool>

    @available(*, unavailable, message: "This must never be accessed directly. Use this property inside a `class` instead.")
    public var wrappedValue: WrappedValue {
        fatalError("This property wrapper must never be accessed directly.")
    }

    public static subscript(
        _enclosingInstance selectingTool: SelectingTool,
        wrapped wrappedKeyPath: KeyPath<SelectingTool, WrappedValue>,
        storage storageKeyPath: KeyPath<SelectingTool, Self>
    ) -> WrappedValue {
        let selectedToolPropertyWrapper = selectingTool[keyPath: storageKeyPath]

        return GenericSelectedCommandLineTool(
            selectingTool: selectingTool,
            selectedTool: selectedToolPropertyWrapper.tool,
            selectedToolCommandName: selectedToolPropertyWrapper.name
        )
    }

    public init(
        of selectingTool: SelectingTool.Type,
        name: String,
        tool: SelectedTool
    ) {
        self.name = name
        self.tool = tool
    }

    public var description: String {
        name
    }

    public var debugDescription: String {
        "_CommandLineToolSelectedTool(selectingTool: \(String(reflecting: SelectingTool.self)), selectedTool: \(String(reflecting: SelectedTool.self)), name: \(String(reflecting: name)))"
    }

    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "name": name,
                "tool": tool
            ],
            displayStyle: .struct
        )
    }
}

