//
// Copyright (c) Vatsal Manot
//

public struct _ShellCommandString: CustomStringConvertible, CustomDebugStringConvertible, Hashable, Sendable, ExpressibleByStringLiteral {
    public var rawValue: String
    public var dialect: _ShellDialect

    public init(
        rawValue: String,
        dialect: _ShellDialect = .posix
    ) {
        self.rawValue = rawValue
        self.dialect = dialect
    }

    public init(
        stringLiteral value: String
    ) {
        self.init(rawValue: value)
    }

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        "_ShellCommandString(rawValue: \(String(reflecting: rawValue)), dialect: \(dialect))"
    }
}
