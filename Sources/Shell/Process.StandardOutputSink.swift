//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
import Swift

extension Process {
    // Passed as the first parameter to `sh` or `shq`, specifying where to direct the output
    public enum StandardOutputSink {
        /// Redirect output to the terminal
        case terminal
        /// Redirect output to the file at the given path, creating if necessary.
        case file(_ path: String)
        /// Redirect output and error streams to the files at the given paths, creating if necessary.
        case split(_ out: String, err: String)
        /// The null device, also known as `/dev/null`
        case null
        
        public static func file(_ url: URL) -> Self {
            Self.file(url._fromFileURLToURL().path)
        }
    }
}

#endif
