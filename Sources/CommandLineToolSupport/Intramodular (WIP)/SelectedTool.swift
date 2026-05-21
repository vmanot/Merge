//
// Copyright (c) Vatsal Manot
//

import Foundation
import Merge

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol CommandLineToolWithSelectedTool: CommandLineTool {
    associatedtype SelectingTool: AnyCommandLineToolWithSelectedTool & CommandLineTool
    associatedtype SelectedCommandLineTool: AnyCommandLineTool & CommandLineTool

    var selectingTool: SelectingTool { get }
    var selectedTool: SelectedCommandLineTool { get }
    var toolSelectionSemantics: AnyCommandLineToolWithSelectedTool.ToolSelectionSemantics { get }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolWithSelectedTool {
    public var toolSelectionSemantics: AnyCommandLineToolWithSelectedTool.ToolSelectionSemantics {
        selectingTool.toolSelectionSemantics
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol CommandLineToolThatResolvesAndInvokesSelectedTool: CommandLineToolWithSelectedTool {
    var selectedToolResolutionSemantics: AnyCommandLineToolWithSelectedTool.SelectedToolResolutionSemantics { get }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolThatResolvesAndInvokesSelectedTool {
    public var selectedToolResolutionSemantics: AnyCommandLineToolWithSelectedTool.SelectedToolResolutionSemantics {
        selectingTool.selectedToolResolutionSemantics
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public protocol _GenericSelectedCommandLineToolProtocol {
    associatedtype SelectingTool: AnyCommandLineToolWithSelectedTool & CommandLineTool
    var selectingTool: SelectingTool { get }

    associatedtype SelectedTool: AnyCommandLineTool & CommandLineTool
    var selectedTool: SelectedTool { get }
    var selectedToolCommandName: String { get }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
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

@dynamicMemberLookup
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public final class GenericSelectedCommandLineTool<SelectingTool, SelectedTool>: AnyCommandLineTool, CommandLineTool, CommandLineToolThatResolvesAndInvokesSelectedTool, _GenericSelectedCommandLineToolProtocol, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable where SelectingTool: AnyCommandLineToolWithSelectedTool & CommandLineTool, SelectedTool: AnyCommandLineTool & CommandLineTool {
    public typealias Command = SelectedTool.Command
    public typealias SummaryContent = SelectedTool.SummaryContent
    public typealias SelectedCommandLineTool = SelectedTool

    public let selectingTool: SelectingTool
    public var selectedTool: SelectedTool
    public let selectedToolCommandName: String

    public override var commandName: CommandLineTool.Name? {
        CommandLineTool.Name(selectedToolCommandName)
    }

    public subscript<Subcommand: AnyCommandLineTool>(
        dynamicMember keyPath: KeyPath<SelectedTool, GenericSubcommand<SelectedTool, Subcommand>>
    ) -> GenericSubcommand<GenericSelectedCommandLineTool<SelectingTool, SelectedTool>, Subcommand> {
        let subcommand = selectedTool[keyPath: keyPath]

        return GenericSubcommand<GenericSelectedCommandLineTool<SelectingTool, SelectedTool>, Subcommand>(
            parent: self,
            command: subcommand.command
        )
    }

    public init(
        selectingTool: SelectingTool,
        selectedTool: SelectedTool,
        selectedToolCommandName: String? = nil
    ) {
        self.selectingTool = selectingTool
        self.selectedTool = selectedTool
        self.selectedToolCommandName = selectedToolCommandName ?? selectedTool.requireCommandName().rawValue
    }

    public var invocationSummary: SelectedTool.SummaryContent {
        selectedTool.invocationSummary
    }

    public var description: String {
        "\(selectingTool.requireCommandName().rawValue) selecting \(selectedToolCommandName)"
    }

    public var debugDescription: String {
        "GenericSelectedCommandLineTool(selectingTool: \(String(reflecting: SelectingTool.self)), selectedTool: \(String(reflecting: SelectedTool.self)), selectedToolCommandName: \(String(reflecting: selectedToolCommandName)))"
    }

    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "selectingTool": selectingTool,
                "selectedTool": selectedTool,
                "selectedToolCommandName": selectedToolCommandName
            ],
            displayStyle: .class
        )
    }

    public func with<T>(
        _ keyPath: ReferenceWritableKeyPath<SelectedTool, T>,
        _ newValue: T
    ) -> Self {
        selectedTool[keyPath: keyPath] = newValue
        return self
    }

    public func callAsFunction() -> Self {
        self
    }

    @inlinable
    public override func withUnsafeSystemShell<R>(
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        try await selectedTool.withUnsafeSystemShell(perform: operation)
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
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
