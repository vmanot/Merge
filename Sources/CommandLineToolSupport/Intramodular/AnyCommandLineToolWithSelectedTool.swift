#if os(macOS)
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
}

extension AnyCommandLineToolWithSelectedTool {
    public struct ToolSelectionSemantics: Hashable, Sendable {
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

#endif
