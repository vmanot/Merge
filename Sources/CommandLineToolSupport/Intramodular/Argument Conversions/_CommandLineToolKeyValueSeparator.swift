//
//  _CommandLineToolKeyValueSeparator.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/11.
//

import Foundation

public enum _CommandLineToolParameterKeyValueSeparator: String, Hashable, Sendable {
    /// Uses a space character as separator between key and value.
    ///
    /// For example: `-o <path>`
    case space = " "
    /// Uses an equal character as separator between key and value.
    ///
    /// For example: `-cxx-interoperability-mode=default` for `xcrun swiftc`
    case equal = "="
    
    /// Uses a plus character as separator between key and value.
    ///
    /// For example: `-framework+UIKit` for legacy `Id` CLT.
    ///
    /// - warning: This is a legacy value style and may not support in the mordern toolchain.
    case plus = "+"
    
    /// Uses a colon character as separator between key and value.
    ///
    /// Commonly used in some Windows CLIs, for example: `/out:program.exe`.
    case colon = ":"
}
