//
// Copyright (c) Vatsal Manot
//


import Diagnostics
import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct CommandLineToolName: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable, ExpressibleByStringLiteral {
    public var argument: CommandLineToolInvocation.Argument

    public init(_ rawValue: String) {
        self.init(CommandLineToolInvocation.Argument(rawValue))
    }

    public init(_ argument: CommandLineToolInvocation.Argument) {
        self.argument = argument
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public var rawValue: String {
        argument.rawValue
    }

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        "CommandLineToolName(\(argument.debugDescription))"
    }

    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "argument": argument,
                "rawValue": rawValue
            ],
            displayStyle: .struct
        )
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineToolName {
    package init(derivingFrom type: Any.Type) {
        self.init("\(type)".lowercased())
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AnyCommandLineTool {
    public func requireCommandName() -> CommandLineToolName {
        guard let result = commandName else {
            let error = _DeveloperError.missingRequiredCommandName(
                toolType: String(reflecting: type(of: self))
            )

            runtimeIssue(error)
            preconditionFailure(error.description)
        }

        return result
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineTool {
    public typealias Name = CommandLineToolName
}

