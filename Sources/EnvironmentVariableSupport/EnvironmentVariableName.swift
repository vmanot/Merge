//
// Copyright (c) Vatsal Manot
//

import Foundation

public struct EnvironmentVariableName: Hashable, Sendable {
    public let rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

extension EnvironmentVariableName: RawRepresentable {
    public init(rawValue: String) {
        self.init(rawValue)
    }
}

extension EnvironmentVariableName: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension EnvironmentVariableName: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

