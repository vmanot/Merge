//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

/// Describes how multi-value parameters are encoded on the command line.
public enum MultiValueParameterEncodingStrategy: Hashable, Sendable {
    /// Each parameter value is attached to an independent key.
    ///
    /// For example: `-Xcc -fmodule-map-file=foo.modulemap -Xcc -fmodules` for `xcrun_swiftc`
    case singleValue
    
    /// Multiple values are attached to the same option key and joined with a whitespace.
    ///
    /// For example: `--platform ios macOS watchOS` for `crowbar-tool`
    case spaceSeparated
}
