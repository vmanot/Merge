//
//  _CommandLineToolOptionKeyConversion.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/11.
//

import Foundation

public enum _CommandLineToolOptionKeyConversion: Hashable, Sendable {
    /// A parameter name prefixed with one hyphen, for example: `-o`, `-output`, etc.
    case hyphenPrefixed
    /// A parameter name prefixed with two hyphens, for example: `--output`, etc.
    case doubleHyphenPrefixed
    /// A parameter name prefixed with a slash, for example: `/out`, etc.
    ///
    /// Commonly used in some Windows CLIs.
    case slashPrefixed
}
