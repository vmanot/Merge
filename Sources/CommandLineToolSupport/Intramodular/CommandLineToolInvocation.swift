//
// Copyright (c) Vatsal Manot
//

import Foundation

/// A structured representation of a rendered command-line tool invocation.
///
/// This preserves the existing shell-rendered component model used by
/// ``CommandLineTool/invocation`` while giving clients a typed value they can
/// inspect before choosing how to execute or display the command.
@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct CommandLineToolInvocation: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
    public struct Argument: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable, ExpressibleByStringLiteral {
        public enum Storage: CustomStringConvertible, CustomDebugStringConvertible, Hashable, Sendable {
            case string(String)
            case path(String)
            case rawBytes([UInt8])
            
            public var description: String {
                switch self {
                    case .string(let value):
                        value
                    case .path(let value):
                        value
                    case .rawBytes(let value):
                        String(decoding: value, as: UTF8.self)
                }
            }
            
            public var debugDescription: String {
                switch self {
                    case .string(let value):
                        ".string(\(String(reflecting: value)))"
                    case .path(let value):
                        ".path(\(String(reflecting: value)))"
                    case .rawBytes(let value):
                        ".rawBytes(\(value))"
                }
            }
        }
        
        public var storage: Storage
        
        public init(storage: Storage) {
            self.storage = storage
        }
        
        public init(_ value: String) {
            self.init(storage: .string(value))
        }
        
        public init(path value: String) {
            self.init(storage: .path(value))
        }
        
        public init(fileURL: URL) {
            self.init(path: fileURL.path)
        }
        
        public init(rawBytes: [UInt8]) {
            self.init(storage: .rawBytes(rawBytes))
        }
        
        public init(stringLiteral value: String) {
            self.init(value)
        }
        
        public var stringValue: String? {
            switch storage {
                case .string(let value):
                    value
                case .path(let value):
                    value
                case .rawBytes(let value):
                    String(bytes: value, encoding: .utf8)
            }
        }
        
        public var rawValue: String {
            switch storage {
                case .string(let value):
                    value
                case .path(let value):
                    value
                case .rawBytes(let value):
                    String(decoding: value, as: UTF8.self)
            }
        }
        
        public var rawBytes: [UInt8] {
            switch storage {
                case .string(let value):
                    Array(value.utf8)
                case .path(let value):
                    Array(value.utf8)
                case .rawBytes(let value):
                    value
            }
        }
        
        public var posixShellEscapedValue: String {
            guard !rawValue.isEmpty else {
                return "''"
            }
            
            return "'" + rawValue.replacingOccurrences(of: "'", with: "'\\''") + "'"
        }
        
        public var description: String {
            rawValue
        }
        
        public var debugDescription: String {
            "CommandLineToolInvocation.Argument(\(storage.debugDescription))"
        }
        
        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "storage": storage,
                    "stringValue": stringValue as Any,
                    "rawValue": rawValue,
                    "rawBytes": rawBytes
                ],
                displayStyle: .struct
            )
        }
    }
    
    /// The semantic invocation components, including the command name.
    public var components: [Component]
    
    public init(components: [Component]) {
        self.components = components
    }
    
    public init(components: Components) {
        self.init(components: components.elements)
    }
    
    public init(argumentValues: [Argument]) {
        self.init(components: Self._components(from: argumentValues))
    }
    
    public init(components: [Argument]) {
        self.init(argumentValues: components)
    }
    
    public init(components: Arguments) {
        self.init(argumentValues: components.elements)
    }
    
    @_disfavoredOverload
    public init(components: [String]) {
        self.init(
            argumentValues: components
                .filter { !$0.isEmpty }
                .map { Argument($0) }
        )
    }
    
    package static func _components(
        from argumentValues: [Argument]
    ) -> [Component] {
        var didReachExecutable = false
        
        return argumentValues.map { argument in
            let component = Component._component(
                fromRawArgument: argument,
                isExecutablePosition: !didReachExecutable,
                allowsEnvironmentAssignment: !didReachExecutable
            )
            
            if component.kind == .executable {
                didReachExecutable = true
            }
            
            return component
        }
    }
    
    public var argumentValues: [Argument] {
        components.flatMap(\.argumentValues)
    }
    
    public var componentList: Components {
        Components(components)
    }
    
    public var rawComponents: [String] {
        argumentValues.map(\.rawValue)
    }
    
    public var executableComponent: Component? {
        components.first { $0.kind == .executable }
    }
    
    public var environmentAssignmentComponents: [Component] {
        components.filter { $0.kind == .environmentAssignment }
    }
    
    /// The rendered command name component, when present.
    public var commandName: String? {
        executableComponent?.argumentValues.first?.rawValue
    }
    
    /// The semantic argument components after the command name.
    public var arguments: [Argument] {
        guard let executableIndex = components.firstIndex(where: { $0.kind == .executable }) else {
            return []
        }
        
        return components[(executableIndex + 1)...].flatMap(\.argumentValues)
    }
    
    public var argumentList: Arguments {
        Arguments(arguments)
    }
    
    /// The shell-rendered display command line.
    public var commandLine: String {
        renderedCommandLine(using: .legacyShellCommandLine)
    }
    
    public var posixShellCommandLine: String {
        renderedCommandLine(using: .posixShellCommandLine)
    }
    
    public var description: String {
        commandLine
    }
    
    public var debugDescription: String {
        "CommandLineToolInvocation(\(String(reflecting: commandLine)))"
    }
    
    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "components": components,
                "argumentValues": argumentValues,
                "rawComponents": rawComponents,
                "environmentAssignmentComponents": environmentAssignmentComponents,
                "commandName": commandName as Any,
                "arguments": arguments,
                "commandLine": commandLine
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
extension CommandLineTools {
    public typealias Invocation = CommandLineToolInvocation
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CommandLineTool {
    /// A structured representation of this tool's rendered invocation.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var commandInvocation: CommandLineToolInvocation {
        get throws {
            try CommandLineToolInvocation(
                components: self.invocationComponents(context: CommandLineToolInvocationSummary.InvocationSummaryContext())
            )
        }
    }
    
    /// The semantic invocation components, including the command name.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var commandInvocationComponents: [CommandLineToolInvocation.Component] {
        get throws {
            try commandInvocation.components
        }
    }
    
    /// The semantic invocation arguments, including the command name.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public var invocationArguments: [CommandLineToolInvocation.Argument] {
        get throws {
            try commandInvocation.argumentValues
        }
    }
}
