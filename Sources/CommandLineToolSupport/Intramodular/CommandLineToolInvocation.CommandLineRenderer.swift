//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation

extension CommandLineToolInvocation {
    /// Renders a structured invocation into a concrete command line string.
    public struct CommandLineRenderer: CustomStringConvertible, Hashable, Sendable {
        public enum Style: Hashable, Sendable {
            case legacyShellCommandLine
            case posixShellCommandLine
        }

        public var style: Style

        public init(style: Style) {
            self.style = style
        }

        public static let legacyShellCommandLine = Self(style: .legacyShellCommandLine)
        public static let posixShellCommandLine = Self(style: .posixShellCommandLine)

        public func render(
            _ invocation: CommandLineToolInvocation
        ) -> String {
            switch style {
                case .legacyShellCommandLine:
                    return invocation.rawComponents.joined(separator: " ")
                case .posixShellCommandLine:
                    return invocation.argumentValues
                        .map(\.posixShellEscapedValue)
                        .joined(separator: " ")
            }
        }

        public var description: String {
            switch style {
                case .legacyShellCommandLine:
                    return "legacyShellCommandLine"
                case .posixShellCommandLine:
                    return "posixShellCommandLine"
            }
        }
    }

    public func renderedCommandLine(
        using renderer: CommandLineRenderer
    ) -> String {
        renderer.render(self)
    }
}

#endif
