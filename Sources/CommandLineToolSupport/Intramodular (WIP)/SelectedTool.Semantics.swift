//
// Copyright (c) Vatsal Manot
//

import Foundation

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
