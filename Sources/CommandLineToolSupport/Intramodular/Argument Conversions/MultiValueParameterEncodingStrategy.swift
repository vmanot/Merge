//
//  MultiValueParameterEncodingStrategy.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/11.
//

import Foundation

/// Describes how multi-value parameters are encoded on the command line.
public enum MultiValueParameterEncodingStrategy {
    /// Each parameter value is attached to an independent key.
    ///
    /// For example: `-Xcc -fmodule-map-file=foo.modulemap -Xcc -fmodules` for `xcrun_swiftc`
    case singleValue
    
    /// Multiple values are attached to the same option key and joined with a whitespace.
    ///
    /// For example: `--platform ios macOS watchOS` for `crowbar-tool`
    case spaceSeparated
}
