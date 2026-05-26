//
// Copyright (c) Vatsal Manot
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolInvocation {
    /// A direct executable-plus-argv lowering of a modeled invocation.
    public struct ExecutableInvocation: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
        public enum Executable: CustomStringConvertible, CustomDebugStringConvertible, Hashable, Sendable {
            case name(String)
            case fileURL(URL)

            public var description: String {
                switch self {
                    case .name(let value):
                        value
                    case .fileURL(let value):
                        value.path
                }
            }

            public var debugDescription: String {
                switch self {
                    case .name(let value):
                        "CommandLineToolInvocation.ExecutableInvocation.Executable.name(\(String(reflecting: value)))"
                    case .fileURL(let value):
                        "CommandLineToolInvocation.ExecutableInvocation.Executable.fileURL(\(String(reflecting: value.path)))"
                }
            }
        }

        public var executable: Executable
        public var arguments: Arguments

        public init(
            executable: Executable,
            arguments: Arguments
        ) {
            self.executable = executable
            self.arguments = arguments
        }

        public var description: String {
            ([executable.description] + arguments.rawValues).joined(separator: " ")
        }

        public var debugDescription: String {
            "CommandLineToolInvocation.ExecutableInvocation(executable: \(executable.debugDescription), arguments: \(arguments.debugDescription))"
        }

        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "executable": executable,
                    "arguments": arguments
                ],
                displayStyle: .struct
            )
        }
    }

    public var executableInvocation: ExecutableInvocation? {
        guard environmentAssignmentComponents.isEmpty else {
            return nil
        }

        guard let executableArgument = executableComponent?.argumentValues.first else {
            return nil
        }

        guard let executableValue = executableArgument.stringValue, !executableValue.isEmpty else {
            return nil
        }

        let executable: ExecutableInvocation.Executable

        if executableValue.contains("/") {
            executable = .fileURL(URL(fileURLWithPath: executableValue))
        } else {
            guard !executableValue.contains(where: \.isWhitespace) else {
                return nil
            }

            executable = .name(executableValue)
        }

        guard arguments.allSatisfy({ $0.stringValue != nil }) else {
            return nil
        }

        return ExecutableInvocation(
            executable: executable,
            arguments: Arguments(arguments)
        )
    }
}
