//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Merge

@dynamicMemberLookup
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Wrapper that renders a selecting tool followed by an independently modeled selected tool.
public final class GenericSelectedCommandLineTool<SelectingTool, SelectedTool>: AnyCommandLineTool, CommandLineTool, CommandLineToolThatResolvesAndInvokesSelectedTool, _GenericSelectedCommandLineToolProtocol, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable where SelectingTool: AnyCommandLineToolWithSelectedTool & CommandLineTool, SelectedTool: AnyCommandLineTool & CommandLineTool {
    public typealias Command = SelectedTool.Command
    public typealias SummaryContent = SelectedTool.SummaryContent
    public typealias SelectedCommandLineTool = SelectedTool

    public let selectingTool: SelectingTool
    public var selectedTool: SelectedTool
    public let selectedToolCommandName: String

    public override var _commandName: String {
        selectedToolCommandName
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
        self.selectedToolCommandName = selectedToolCommandName ?? selectedTool._commandName
    }

    public var invocationSummary: SelectedTool.SummaryContent {
        selectedTool.invocationSummary
    }

    public var description: String {
        "\(selectingTool._commandName) selecting \(selectedToolCommandName)"
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

#endif
