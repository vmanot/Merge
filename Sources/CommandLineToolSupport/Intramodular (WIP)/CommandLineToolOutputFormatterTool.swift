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
    var outputFormattingSemantics: CommandLineToolOutputFormattingSemantics { get }
}

extension CommandLineToolOutputFormatterTool {
    public var outputFormattingSemantics: CommandLineToolOutputFormattingSemantics {
        .standardOutputFormatter
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
/// Describes which stream a formatter consumes and what kind of output it intends to produce.
public struct CommandLineToolOutputFormattingSemantics: Hashable, Sendable {
    public var inputStream: InputStream
    public var outputIntent: OutputIntent

    public init(
        inputStream: InputStream,
        outputIntent: OutputIntent
    ) {
        self.inputStream = inputStream
        self.outputIntent = outputIntent
    }
}

extension CommandLineToolOutputFormattingSemantics {
    public enum InputStream: Hashable, Sendable {
        case standardOutput
    }

    public enum OutputIntent: Hashable, Sendable {
        case humanReadableFormatting
    }
}

extension CommandLineToolOutputFormattingSemantics {
    public static var standardOutputFormatter: Self {
        Self(
            inputStream: .standardOutput,
            outputIntent: .humanReadableFormatting
        )
    }
}

#endif
