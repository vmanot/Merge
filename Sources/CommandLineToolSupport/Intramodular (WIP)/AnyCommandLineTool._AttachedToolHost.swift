//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation

extension AnyCommandLineTool {
    @available(macOS 11.0, *)
    @available(iOS, unavailable)
    @available(macCatalyst, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public enum _AttachedToolHost: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
        case toolThatResolvesAndInvokesSelectedTool(
            selectingTool: any AnyCommandLineToolWithSelectedTool & CommandLineTool,
            selectedToolCommandName: String?
        )

        public static func toolThatResolvesAndInvokesSelectedTool(
            _ selectingTool: any AnyCommandLineToolWithSelectedTool & CommandLineTool,
            selectedToolCommandName: String? = nil
        ) -> Self {
            .toolThatResolvesAndInvokesSelectedTool(
                selectingTool: selectingTool,
                selectedToolCommandName: selectedToolCommandName
            )
        }

        public var description: String {
            switch self {
                case .toolThatResolvesAndInvokesSelectedTool(let selectingTool, let selectedToolCommandName):
                    let selectedToolDescription = selectedToolCommandName.map { " selecting \($0)" } ?? ""

                    return "\(selectingTool.requireCommandName().rawValue)\(selectedToolDescription)"
            }
        }

        public var debugDescription: String {
            switch self {
                case .toolThatResolvesAndInvokesSelectedTool(let selectingTool, let selectedToolCommandName):
                    return "AnyCommandLineTool._AttachedToolHost.toolThatResolvesAndInvokesSelectedTool(selectingTool: \(String(reflecting: type(of: selectingTool))), selectedToolCommandName: \(String(reflecting: selectedToolCommandName)))"
            }
        }

        public var customMirror: Mirror {
            switch self {
                case .toolThatResolvesAndInvokesSelectedTool(let selectingTool, let selectedToolCommandName):
                    return Mirror(
                        self,
                        children: [
                            "case": "toolThatResolvesAndInvokesSelectedTool",
                            "selectingTool": selectingTool,
                            "selectedToolCommandName": selectedToolCommandName as Any
                        ],
                        displayStyle: .enum
                    )
            }
        }
    }
}

extension AnyCommandLineTool._AttachedToolHost {
    var _selectingTool: AnyCommandLineToolWithSelectedTool {
        switch self {
            case .toolThatResolvesAndInvokesSelectedTool(let selectingTool, _):
                return selectingTool
        }
    }

    var _selectedToolCommandNameOverride: String? {
        switch self {
            case .toolThatResolvesAndInvokesSelectedTool(_, let selectedToolCommandName):
                return selectedToolCommandName
        }
    }

    func _invocationArguments(
        hosting invocationArguments: CommandLineToolInvocation.Arguments,
        selectedTool: AnyCommandLineTool,
        context: CommandLineToolInvocationSummary.InvocationSummaryContext
    ) throws -> CommandLineToolInvocation.Arguments {
        switch self {
            case .toolThatResolvesAndInvokesSelectedTool(let selectingTool, let selectedToolCommandName):
                var result = CommandLineToolInvocation.Arguments([
                    CommandLineToolInvocation.Argument(selectingTool.requireCommandName().rawValue)
                ])

                try result.append(
                    contentsOf: selectingTool._defaultInvocationArguments(
                        context: context,
                        positions: [.local]
                    )
                )

                var selectedInvocationArguments = invocationArguments

                if !selectedInvocationArguments.elements.isEmpty {
                    selectedInvocationArguments.elements.removeFirst()
                }

                result.elements.append(
                    CommandLineToolInvocation.Argument(selectedToolCommandName ?? selectedTool.requireCommandName().rawValue)
                )
                result.elements.append(contentsOf: selectedInvocationArguments.elements)

                try result.append(
                    contentsOf: selectingTool._defaultInvocationArguments(
                        context: context,
                        positions: [.lastCommand]
                    )
                )

                return result
        }
    }
}

#endif
