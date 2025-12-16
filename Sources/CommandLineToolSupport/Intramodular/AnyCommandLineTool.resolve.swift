//
//  AnyCommandLineTool+Resolve.swift
//  Merge
//
//  Created by Yanan Li on 2025/12/12.
//

import Foundation
import Swallow
import Runtime

extension AnyCommandLineTool {
    public func resolve(in context: _CommandLineToolResolutionContext) throws -> _ResolvedCommandLineToolDescription {
        let mirror = try InstanceMirror(reflecting: self)
        
        var _resolvedArguments: _ResolvedCommandLineToolDescription.ResolvedArguments = []
        var _resolvedSubcommmands: _ResolvedCommandLineToolDescription.ResolvedSubcommands = []
        
        for (key, value) in mirror.children {
            let resolvingID = _ResolvedCommandLineToolDescription.ArgumentID(
                rawValue: key.stringValue.dropPrefixIfPresent("_") // property wrapper always includes a prefix `_`
            )
            
            if let parameter = value as? (any _CommandLineToolParameterProtocol) {
                _resolveParameter(
                    parameter,
                    resolvingID: resolvingID,
                    context: context,
                    into: &_resolvedArguments
                )
            } else if let flag = value as? (any _CommandLineToolFlagProtocol) {
                _resolveFlag(
                    flag,
                    resolvingID: resolvingID,
                    context: context,
                    into: &_resolvedArguments
                )
            } else if let subcommand = value as? (any _CommandLineToolSubcommandProtocol) {
                try _resolveSubcommand(
                    subcommand,
                    resolvingID: resolvingID,
                    context: context,
                    into: &_resolvedSubcommmands
                )
            }
        }
        
        return _ResolvedCommandLineToolDescription(
            toolName: _commandName,
            arguments: _resolvedArguments,
            subcommands: _resolvedSubcommmands
        )
    }
    
    private func _resolveSubcommand(
        _ subcommand: any _CommandLineToolSubcommandProtocol,
        resolvingID: _ResolvedCommandLineToolDescription.ArgumentID,
        context: _CommandLineToolResolutionContext,
        into resolved: inout _ResolvedCommandLineToolDescription.ResolvedSubcommands
    ) throws {
        try resolved.append(
            _ResolvedCommandLineToolDescription.Subcommand(
                id: resolvingID,
                name: subcommand.command._commandName,
                _resolvedDescription: subcommand.command.resolve(in: context)
            ).erasedToAnyResolvedCommandLineToolMetadata()
        )
    }

    private func _resolveFlag(
        _ flag: any _CommandLineToolFlagProtocol,
        resolvingID: _ResolvedCommandLineToolDescription.ArgumentID,
        context: _CommandLineToolResolutionContext,
        into resolved: inout _ResolvedCommandLineToolDescription.ResolvedArguments
    ) {
        switch flag._representaton {
            case .custom:
                resolved.append(
                    _ResolvedCommandLineToolDescription.CustomFlag(
                        id: resolvingID,
                        value: flag.wrappedValue,
                        valueType: type(of: flag.wrappedValue),
                    ).erasedToAnyResolvedCommandLineToolMetadata()
                )
            case .counter(let conversion, let name):
                resolved.append(
                    _ResolvedCommandLineToolDescription.SimpleFlag(
                        id: resolvingID,
                        conversion: conversion ?? defaultKeyConversion(name),
                        name: name,
                        inversion: nil,
                        defaultBooleanValue: nil,
                        isOn: (flag.wrappedValue as! Int) > 0
                    ).erasedToAnyResolvedCommandLineToolMetadata()
                )
            case .boolean(let conversion, let name, let defaultValue):
                resolved.append(
                    _ResolvedCommandLineToolDescription.SimpleFlag(
                        id: resolvingID,
                        conversion: conversion ?? defaultKeyConversion(name),
                        name: name,
                        inversion: nil, // only be able to switch to another state (true / false)
                        defaultBooleanValue: defaultValue,
                        isOn: (flag.wrappedValue as! Bool)
                    ).erasedToAnyResolvedCommandLineToolMetadata()
                )
            case .optionalBoolean(let conversion, let name, let inversion):
                resolved.append(
                    _ResolvedCommandLineToolDescription.SimpleFlag(
                        id: resolvingID,
                        conversion: conversion ?? defaultKeyConversion(name),
                        name: name,
                        inversion: inversion,
                        defaultBooleanValue: nil,
                        isOn: flag.wrappedValue as! Optional<Bool>
                    ).erasedToAnyResolvedCommandLineToolMetadata()
                )
        }
    }
    
    private func _resolveParameter(
        _ parameter: any _CommandLineToolParameterProtocol,
        resolvingID: _ResolvedCommandLineToolDescription.ArgumentID,
        context: _CommandLineToolResolutionContext,
        into resolved: inout _ResolvedCommandLineToolDescription.ResolvedArguments
    ) {
        if let name = parameter.name {
            resolved.append(
                _ResolvedCommandLineToolDescription.Option(
                    id: resolvingID,
                    conversion: _effectiveKeyConversion(
                        explicit: parameter.optionKeyConversion,
                        nameOfKey: name
                    ),
                    name: name,
                    separator: parameter.keyValueSeparator,
                    multiValueEncoding: parameter.multiValueEncodingStrategy,
                    value: parameter.wrappedValue,
                    valueType: type(of: parameter.wrappedValue)
                ).erasedToAnyResolvedCommandLineToolMetadata()
            )
        } else {
            resolved.append(
                _ResolvedCommandLineToolDescription.Argument(
                    id: resolvingID,
                    value: parameter.wrappedValue,
                    valueType: type(of: parameter.wrappedValue)
                ).erasedToAnyResolvedCommandLineToolMetadata()
            )
        }
    }
}

// MARK: - Helpers

extension AnyCommandLineTool {
    private func _effectiveKeyConversion(
        explicit: _CommandLineToolOptionKeyConversion?,
        nameOfKey: String
    ) -> _CommandLineToolOptionKeyConversion {
        explicit ?? keyConversion ?? defaultKeyConversion(nameOfKey)
    }
    
    private func defaultKeyConversion(_ name: String) -> _CommandLineToolOptionKeyConversion {
        name.count > 1 ? .doubleHyphenPrefixed : .hyphenPrefixed
    }
}
