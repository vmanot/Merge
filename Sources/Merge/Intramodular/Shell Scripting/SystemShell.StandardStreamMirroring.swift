//
// Copyright (c) Vatsal Manot
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemShell {
    public struct StandardStreamMirroring: Hashable, Sendable {
        public enum Target: Hashable, Sendable {
            case disabled
            case terminal
            case file(URL)
        }

        public var standardOutput: Target
        public var standardError: Target

        public init(
            standardOutput: Target,
            standardError: Target
        ) {
            self.standardOutput = standardOutput
            self.standardError = standardError
        }

        public static let disabled = Self(
            standardOutput: .disabled,
            standardError: .disabled
        )

        public static let terminal = Self(
            standardOutput: .terminal,
            standardError: .terminal
        )

        public static func file(
            _ url: URL
        ) -> Self {
            Self(
                standardOutput: .file(url),
                standardError: .file(url)
            )
        }

        public static func split(
            standardOutput: URL,
            standardError: URL
        ) -> Self {
            Self(
                standardOutput: .file(standardOutput),
                standardError: .file(standardError)
            )
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SystemShell.StandardStreamMirroring {
    package init(
        processStandardOutputSink sink: _ProcessStandardOutputSink
    ) {
        switch sink {
            case .terminal:
                self = .terminal
            case .filePath(let path):
                self = .file(URL(fileURLWithPath: path))
            case .split(let outputPath, let errorPath):
                self = .split(
                    standardOutput: URL(fileURLWithPath: outputPath),
                    standardError: URL(fileURLWithPath: errorPath)
                )
            case .null:
                self = .disabled
        }
    }

    package init(
        options: [_AsyncProcessOption]?
    ) {
        guard let sink = options?.compactMap({ option -> _ProcessStandardOutputSink? in
            guard case let ._forwardStdoutStderr(sink) = option else {
                return nil
            }

            return sink
        }).last else {
            self = .disabled

            return
        }

        self.init(processStandardOutputSink: sink)
    }

    package func _legacyForwardingOption() throws -> _AsyncProcessOption? {
        switch (standardOutput, standardError) {
            case (.disabled, .disabled):
                return nil
            case (.terminal, .terminal):
                return ._forwardStdoutStderr(to: .terminal)
            case (.file(let url), .file(let otherURL)) where url == otherURL:
                return ._forwardStdoutStderr(to: .file(url))
            case (.file(let outputURL), .file(let errorURL)):
                return ._forwardStdoutStderr(
                    to: .split(
                        outputURL._fromFileURLToURL().path,
                        err: errorURL._fromFileURLToURL().path
                    )
                )
            default:
                throw SystemShell._DeveloperError.unsupportedStandardStreamMirroring(self)
        }
    }
}
