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
open class AnyCommandLineToolWithSelectedTool: AnyCommandLineTool {
    open var toolSelectionSemantics: ToolSelectionSemantics {
        .staticExplicitArgument
    }

    open var selectedToolResolutionSemantics: SelectedToolResolutionSemantics {
        .resolvesBeforeInvocationAndInvokesThroughSelectingTool
    }
}

extension AnyCommandLineToolWithSelectedTool {
    public struct ToolSelectionSemantics: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
        public enum Phase: Hashable, Sendable {
            case beforeInvocation
            case duringInvocation
            case afterProcessStart
        }

        public enum Mutability: Hashable, Sendable {
            case fixedOnceSelected
            case configurableBeforeInvocation
            case mayChangeDuringInvocation
        }

        public enum Disclosure: Hashable, Sendable {
            case staticallyKnown
            case explicitArgument
            case inferredByTool
            case observableOnlyAtRuntime
        }

        public enum ArgumentBoundary: Hashable, Sendable {
            case selectedToolConsumesRemainingArguments
            case explicitSeparator(String)
            case toolSpecific
        }

        public var phase: Phase
        public var mutability: Mutability
        public var disclosure: Disclosure
        public var argumentBoundary: ArgumentBoundary

        public init(
            phase: Phase,
            mutability: Mutability,
            disclosure: Disclosure,
            argumentBoundary: ArgumentBoundary
        ) {
            self.phase = phase
            self.mutability = mutability
            self.disclosure = disclosure
            self.argumentBoundary = argumentBoundary
        }

        public var description: String {
            "\(phase), \(disclosure)"
        }

        public var debugDescription: String {
            "ToolSelectionSemantics(phase: \(phase), mutability: \(mutability), disclosure: \(disclosure), argumentBoundary: \(argumentBoundary))"
        }

        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "phase": phase,
                    "mutability": mutability,
                    "disclosure": disclosure,
                    "argumentBoundary": argumentBoundary
                ],
                displayStyle: .struct
            )
        }

        public static var staticExplicitArgument: Self {
            Self(
                phase: .beforeInvocation,
                mutability: .fixedOnceSelected,
                disclosure: .explicitArgument,
                argumentBoundary: .selectedToolConsumesRemainingArguments
            )
        }

        public static var dynamicRuntimeSelection: Self {
            Self(
                phase: .duringInvocation,
                mutability: .mayChangeDuringInvocation,
                disclosure: .observableOnlyAtRuntime,
                argumentBoundary: .toolSpecific
            )
        }
    }

    public struct SelectedToolResolutionSemantics: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
        public enum Phase: Hashable, Sendable {
            case beforeInvocation
            case duringInvocation
            case afterProcessStart
        }

        public enum Invocation: Hashable, Sendable {
            case throughSelectingTool
            case directResolvedExecutable
        }

        public enum ExecutableDisclosure: Hashable, Sendable {
            case selectedToolName
            case resolvedExecutablePath
            case observableOnlyAtRuntime
        }

        public var phase: Phase
        public var invocation: Invocation
        public var executableDisclosure: ExecutableDisclosure

        public init(
            phase: Phase,
            invocation: Invocation,
            executableDisclosure: ExecutableDisclosure
        ) {
            self.phase = phase
            self.invocation = invocation
            self.executableDisclosure = executableDisclosure
        }

        public var description: String {
            "\(phase), \(invocation)"
        }

        public var debugDescription: String {
            "SelectedToolResolutionSemantics(phase: \(phase), invocation: \(invocation), executableDisclosure: \(executableDisclosure))"
        }

        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "phase": phase,
                    "invocation": invocation,
                    "executableDisclosure": executableDisclosure
                ],
                displayStyle: .struct
            )
        }

        public static var resolvesBeforeInvocationAndInvokesThroughSelectingTool: Self {
            Self(
                phase: .beforeInvocation,
                invocation: .throughSelectingTool,
                executableDisclosure: .selectedToolName
            )
        }

        public static var resolvesBeforeInvocationAndInvokesExecutableDirectly: Self {
            Self(
                phase: .beforeInvocation,
                invocation: .directResolvedExecutable,
                executableDisclosure: .resolvedExecutablePath
            )
        }

        public static var dynamicRuntimeResolution: Self {
            Self(
                phase: .duringInvocation,
                invocation: .throughSelectingTool,
                executableDisclosure: .observableOnlyAtRuntime
            )
        }
    }
}

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

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
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
