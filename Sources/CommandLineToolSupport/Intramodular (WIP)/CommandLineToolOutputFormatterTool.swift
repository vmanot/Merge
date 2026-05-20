//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// A command-line tool whose primary role is formatting another command's output stream.
public protocol CommandLineToolOutputFormatterTool: CommandLineTool {
    typealias Semantics = _CommandLineToolOutputFormatterTool_Semantics

    var outputFormattingSemantics: Semantics { get }
}

extension CommandLineToolOutputFormatterTool {
    public var outputFormattingSemantics: Semantics {
        .standardOutputFormatter
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Describes which stream a formatter consumes and what kind of output it intends to produce.
public struct _CommandLineToolOutputFormatterTool_Semantics: Hashable, Sendable {
    public var inputStream: InputStream
    public var outputIntent: OutputIntent
    public var streamEffects: Set<StreamEffect>

    public init(
        inputStream: InputStream,
        outputIntent: OutputIntent,
        streamEffects: Set<StreamEffect> = [.humanReadableFormatting]
    ) {
        self.inputStream = inputStream
        self.outputIntent = outputIntent
        self.streamEffects = streamEffects
    }
}

extension _CommandLineToolOutputFormatterTool_Semantics {
    public enum InputStream: Hashable, Sendable {
        case standardOutput
    }

    public enum OutputIntent: Hashable, Sendable {
        case humanReadableFormatting
    }

    public struct StreamEffect: CustomStringConvertible, Hashable, Sendable {
        public struct Key: CustomStringConvertible, ExpressibleByStringLiteral, Hashable, Sendable {
            public var rawValue: String

            public init(_ rawValue: String) {
                self.rawValue = rawValue
            }

            public init(stringLiteral value: String) {
                self.init(value)
            }

            public var description: String {
                rawValue
            }
        }

        public enum Composition: Hashable, Sendable {
            case exclusive
            case repeatable
        }

        public var key: Key
        public var composition: Composition

        public init(
            key: Key,
            composition: Composition
        ) {
            self.key = key
            self.composition = composition
        }

        public var description: String {
            key.description
        }
    }
}

extension _CommandLineToolOutputFormatterTool_Semantics.StreamEffect {
    public static var humanReadableFormatting: Self {
        Self(
            key: "human-readable-output-formatting",
            composition: .exclusive
        )
    }
}

extension _CommandLineToolOutputFormatterTool_Semantics {
    public static var standardOutputFormatter: Self {
        Self(
            inputStream: .standardOutput,
            outputIntent: .humanReadableFormatting
        )
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(*, deprecated, renamed: "_CommandLineToolOutputFormatterTool_Semantics")
public typealias CommandLineToolOutputFormattingSemantics = _CommandLineToolOutputFormatterTool_Semantics

#endif
