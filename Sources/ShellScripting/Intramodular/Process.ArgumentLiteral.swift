//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation

extension Process {
    public struct ArgumentLiteral: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, ExpressibleByStringLiteral, Sendable {
        public enum Storage: CustomStringConvertible, CustomDebugStringConvertible, Hashable, Sendable {
            case string(String)
            case rawBytes([UInt8])

            public var description: String {
                switch self {
                    case .string(let value):
                        value
                    case .rawBytes(let value):
                        String(decoding: value, as: UTF8.self)
                }
            }

            public var debugDescription: String {
                switch self {
                    case .string(let value):
                        ".string(\(String(reflecting: value)))"
                    case .rawBytes(let value):
                        ".rawBytes(\(value))"
                }
            }
        }

        /// Legacy shell-escaping controls for `ArgumentLiteral` string rendering.
        public enum Option: Hashable, Sendable {
            case escapeSpaces
        }

        public enum URLArgumentRepresentation: Hashable, Sendable {
            case filePath
            case absoluteString
        }

        public let storage: Storage
        let options: Set<Option>
        let isQuoted: Bool

        public init(
            storage: Storage,
            options: Set<Option> = [.escapeSpaces],
            isQuoted: Bool = false
        ) {
            self.storage = storage
            self.options = options
            self.isQuoted = isQuoted
        }

        var value: String {
            rawValue
        }

        public var stringValue: String? {
            switch storage {
                case .string(let value):
                    value
                case .rawBytes(let value):
                    String(bytes: value, encoding: .utf8)
            }
        }

        /// The unescaped argument value, decoding raw bytes as UTF-8 when needed.
        public var rawValue: String {
            switch storage {
                case .string(let value):
                    value
                case .rawBytes(let value):
                    String(decoding: value, as: UTF8.self)
            }
        }

        public var rawBytes: [UInt8] {
            switch storage {
                case .string(let value):
                    Array(value.utf8)
                case .rawBytes(let value):
                    value
            }
        }

        public init(
            _ value: String,
            options: Set<Option> = [.escapeSpaces],
            isQuoted: Bool = false
        ) {
            self.init(
                storage: .string(value),
                options: options,
                isQuoted: isQuoted
            )
        }

        public init(
            rawBytes: [UInt8],
            options: Set<Option> = [.escapeSpaces],
            isQuoted: Bool = false
        ) {
            self.init(
                storage: .rawBytes(rawBytes),
                options: options,
                isQuoted: isQuoted
            )
        }

        @_disfavoredOverload
        public init(
            _ value: URL,
            representation: URLArgumentRepresentation = .filePath,
            options: Set<Option> = [.escapeSpaces],
            isQuoted: Bool = false
        ) {
            let value: String = switch representation {
                case .filePath:
                    value.isFileURL ? value.path : value.absoluteString
                case .absoluteString:
                    value.absoluteString
            }

            self.init(
                value,
                options: options,
                isQuoted: isQuoted
            )
        }

        public init(
            stringLiteral value: String
        ) {
            self.init(value)
        }

        /// Returns the argument value escaped for a POSIX-style shell command line.
        public var posixShellEscapedValue: String {
            var result = rawValue

            if isQuoted {
                result = result.replacingOccurrences(of: "\\", with: "\\\\")
                result = result.replacingOccurrences(of: "\"", with: "\\\"")
                result = "\"" + result + "\""
            } else {
                result = result.replacingOccurrences(of: "\\", with: "\\\\")

                if options.contains(.escapeSpaces) {
                    result = result.replacingOccurrences(of: " ", with: "\\ ")
                }

                result = result.replacingOccurrences(of: "'", with: "\\'")
                result = result.replacingOccurrences(of: "\"", with: "\\\"")
            }

            return result
        }

        public func escapedValue(
            for shellDialect: _ShellDialect
        ) -> String {
            switch shellDialect {
                case .posix:
                    posixShellEscapedValue
            }
        }

        /// Returns the argument value with legacy shell escaping applied.
        @available(*, deprecated, renamed: "posixShellEscapedValue")
        public var escapedValue: String {
            posixShellEscapedValue
        }

        public var description: String {
            rawValue
        }

        public var debugDescription: String {
            "Process.ArgumentLiteral(\(storage.debugDescription), isQuoted: \(isQuoted), options: \(options))"
        }

        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "storage": storage,
                    "stringValue": stringValue as Any,
                    "rawValue": rawValue,
                    "rawBytes": rawBytes,
                    "options": options,
                    "isQuoted": isQuoted
                ],
                displayStyle: .struct
            )
        }
    }
}

#endif
