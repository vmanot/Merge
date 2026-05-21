//
// Copyright (c) Vatsal Manot
//


import Foundation

extension AnyCommandLineToolWithSelectedTool {
    public struct SelectedToolResolutionSemantics: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
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
    }
}

extension AnyCommandLineToolWithSelectedTool.SelectedToolResolutionSemantics {
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
}

extension AnyCommandLineToolWithSelectedTool.SelectedToolResolutionSemantics {
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

