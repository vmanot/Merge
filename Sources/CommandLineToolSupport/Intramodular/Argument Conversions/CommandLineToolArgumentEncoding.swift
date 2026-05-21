//
// Copyright (c) Vatsal Manot
//

import Foundation

public enum MultiValueParameterEncodingStrategy: Hashable, Sendable {
    case singleValue
    case spaceSeparated
}

public enum _CommandLineToolParameterKeyValueSeparator: String, Hashable, Sendable {
    case space = " "
    case equal = "="
    case plus = "+"
    case colon = ":"
}

public enum _CommandLineToolOptionKeyConversion: Hashable, Sendable {
    case hyphenPrefixed
    case doubleHyphenPrefixed
    case slashPrefixed
}

extension _CommandLineToolOptionKeyConversion {
    public var prefix: String {
        switch self {
            case .hyphenPrefixed: "-"
            case .doubleHyphenPrefixed: "--"
            case .slashPrefixed: "/"
        }
    }

    public func argumentKey(for name: String) -> String { prefix + name }
}
