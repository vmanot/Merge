//
// Copyright (c) Vatsal Manot
//


import Foundation
import ShellScripting

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

        public func renderShellCommandString(
            _ invocation: CommandLineToolInvocation
        ) -> _ShellCommandString {
            let rawValue: String

            switch style {
                case .legacyShellCommandLine:
                    rawValue = invocation.rawComponents.joined(separator: " ")
                case .posixShellCommandLine:
                    rawValue = invocation.argumentValues
                        .map(\.posixShellEscapedValue)
                        .joined(separator: " ")
            }

            return _ShellCommandString(rawValue: rawValue, dialect: .posix)
        }

        public func render(
            _ invocation: CommandLineToolInvocation
        ) -> String {
            renderShellCommandString(invocation).rawValue
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

    public func renderedShellCommandString(
        using renderer: CommandLineRenderer
    ) -> _ShellCommandString {
        renderer.renderShellCommandString(self)
    }
}
