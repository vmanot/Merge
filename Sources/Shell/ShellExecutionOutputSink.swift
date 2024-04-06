//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

// Passed as the first parameter to `sh` or `shq`, specifying where to direct the output
public enum ShellExecutionOutputSink {
    case terminal /// Redirect output to the terminal
    case file(_ path: String) /// Redirect output to the file at the given path, creating if necessary.
    case split(_ out: String, err: String) /// Redirect output and error streams to the files at the given paths, creating if necessary.
    case null /// The null device, also known as `/dev/null`
}

extension ShellExecutionOutputSink {
    public static func file(_ url: URL) -> Self {
        Self.file(url._fromFileURLToURL().path)
    }
}
