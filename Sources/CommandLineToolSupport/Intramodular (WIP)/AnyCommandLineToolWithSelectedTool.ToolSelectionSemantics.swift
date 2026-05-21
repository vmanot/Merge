//
// Copyright (c) Vatsal Manot
//


import Foundation

extension AnyCommandLineToolWithSelectedTool {
    public struct ToolSelectionSemantics: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
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
    }
}

extension AnyCommandLineToolWithSelectedTool.ToolSelectionSemantics {
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
}

extension AnyCommandLineToolWithSelectedTool.ToolSelectionSemantics {
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

