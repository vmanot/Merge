//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Foundation
import Merge
import Runtime

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
open class AnyCommandLineTool: Logging {
    public lazy var logger = PassthroughLogger(source: self)
    
    public var environmentVariables: [String: any CLT.EnvironmentVariableValue] = [:]
    public var currentDirectoryURL: URL? = nil
    
    public init() {
        
    }
    
    @discardableResult
    open func withUnsafeSystemShell<R>(
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        let environmentVariables = _resolveEnvironmentVariables()
        
        let shell = SystemShell(
            environment: environmentVariables.mapValues({ String(describing: $0) }),
            currentDirectoryURL: currentDirectoryURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
            options: [._forwardStdoutStderr]
        )
        
        let result: R = try await operation(shell)
        
        return result
    }
    
    /// Resolves the full list of environment variables by combining manually set environment variables with runtime-reflected variables that are defined via the `@EnvironmentVariable` property wrapper.
    private func _resolveEnvironmentVariables() -> [String: any CLT.EnvironmentVariableValue] {
        var result: [String: any CLT.EnvironmentVariableValue] = environmentVariables
        
        let mirror = InstanceMirror(self)!
        
        for child in mirror.children {
            guard let propertyWrapper = child.value as? (any _CommandLineToolEnvironmentVariableProtocol) else {
                continue
            }
            
            let environmentVariableName = propertyWrapper.name
            let environmentVariableValue: any CLT.EnvironmentVariableValue = propertyWrapper.wrappedValue

            if environmentVariables.contains(key: environmentVariableName) {
                fatalError("conflict for \(environmentVariableName)")
            }
        
            result[environmentVariableName] = environmentVariableValue
        }
        
        return result
    }
    
    /// The foundational list of command-line arguments that identify and invoke the underlying system tool.
    ///
    /// These arguments always appear at the beginning of the serialized command, for example:
    /// - `["xcrun", "swiftc"]`
    /// - `["xcrun"]`
    /// - `["xcodebuild"]`
    open var baseArguments: [String] {
        fatalError(.abstract)
    }
    
    open func serializedCommand(actionOrSubCommand: String) -> String {
        let mirror = InstanceMirror(self)!
        
        var components = baseArguments
        components.append(actionOrSubCommand)
        
        for child in mirror.children {
            let parameter = child.value as? (any _CommandLineToolParameterProtocol)
            guard let parameter else { continue }
            
            if let optionalValue = parameter.wrappedValue as? (any OptionalProtocol),
                optionalValue.isNil {
                continue // Skip this parameter if the value is empty.
            }
            
            var argument = ""
            
            func _singleValueArgument(
                key: _CommandLineToolParameterOptionKey?,
                keyValueSeparator: _CommandLineToolParameterKeyValueSeparator,
                value: any CLT.ArgumentValueConvertible,
            ) -> String {
                var argument = ""
                if let key {
                    argument += key.argumentValue
                }
                argument += keyValueSeparator.rawValue
                argument += value.argumentValue
                return argument
            }
            
            if let multiValueEncodingStrategy = parameter.multiValueEncodingStrategy {
                let array = parameter.wrappedValue as? Array<(any CLT.ArgumentValueConvertible)>
                guard let array else { continue }
                
                switch multiValueEncodingStrategy {
                    case .singleValue:
                        argument = array
                            .map {
                                _singleValueArgument(
                                    key: parameter.key,
                                    keyValueSeparator: parameter.keyValueSeparator,
                                    value: $0
                                )
                            }
                            .joined(separator: " ")
                    case .spaceSeparated:
                        assert(
                            parameter.keyValueSeparator == .space,
                            "key value separator conflicts with the multi value encoding strategy. You must specify set both to `.space`."
                        )
                        if let key = parameter.key {
                            argument += key.argumentValue
                        }
                        argument += array.map(\.argumentValue).joined(separator: " ")
                }
            } else {
                let value = parameter.wrappedValue as? (any CLT.ArgumentValueConvertible)
                guard let value else { continue }
                
                argument = _singleValueArgument(
                    key: parameter.key,
                    keyValueSeparator: parameter.keyValueSeparator,
                    value: value
                )
            }

            components.append(argument)
        }
        
        return components.joined(separator: " ")
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AnyCommandLineTool {
    public func withUnsafeSystemShell<R>(
        sink: _ProcessStandardOutputSink,
        perform operation: (SystemShell) async throws -> R
    ) async throws -> R {
        try await withUnsafeSystemShell { shell in
            shell.options ??= []
            shell.options?.removeAll(where: {
                $0._stdoutStderrSink != .null
            })
            shell.options?.append(._forwardStdoutStderr(to: sink))
            
            return try await operation(shell)
        }
    }
}
