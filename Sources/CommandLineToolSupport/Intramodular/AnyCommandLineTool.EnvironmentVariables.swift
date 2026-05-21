//
// Copyright (c) Vatsal Manot
//

import Foundation

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension AnyCommandLineTool {
    package func _resolveEnvironmentVariables() -> [String: any CLT.EnvironmentVariableValue] {
        _CommandLineToolEnvironmentVariableResolver(tool: self).resolve()
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct _CommandLineToolEnvironmentVariableResolver {
    var tool: AnyCommandLineTool

    func resolve() -> [String: any CLT.EnvironmentVariableValue] {
        var result = tool.environmentVariables

        for variable in reflectedEnvironmentVariables() {
            guard !tool.environmentVariables.contains(key: variable.name) else {
                fatalError("conflict for \(variable.name)")
            }

            result[variable.name] = variable.value
        }

        return result
    }

    private func reflectedEnvironmentVariables() -> [(name: String, value: any CLT.EnvironmentVariableValue)] {
        Mirror(reflecting: tool).children.compactMap { child in
            guard let propertyWrapper = child.value as? any _CommandLineToolEnvironmentVariableProtocol else {
                return nil
            }

            return (
                name: propertyWrapper.name,
                value: propertyWrapper.wrappedValue
            )
        }
    }
}
