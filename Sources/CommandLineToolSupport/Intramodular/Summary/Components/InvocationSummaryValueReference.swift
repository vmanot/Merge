//
//  InvocationSummaryValue.swift
//  Merge
//
//  Created by Yanan Li on 2026/1/5.
//

import Foundation
import Swallow

public struct InvocationSummaryValueReference<Command: AnyCommandLineTool, Value: InvocationSummaryValue>: InvocationSummary {
    let value: Value

    public init(_ value: Value) {
        self.value = value
    }
    
    public var wrappedValue: Value.WrappedValue {
        value.wrappedValue
    }
    
    public func makeInvocationArguments(context: InvocationSummaryContext<Command>) throws -> [String] {
        let command = context.command
        let resolved = try value.resolve(
            in: .init(
                resolvingID: _ResolvedCommandLineToolDescription.ArgumentID(
                    rawValue: UUID().uuidString, // construct a temporary string.
                    commandName: command._commandName
                ),
                defaultKeyConversion: command.keyConversion
            )
        )
        
        if let argument = resolved.invocationArgument {
            return [argument]
        } else {
            return []
        }
    }
}

public protocol InvocationSummaryValue: PropertyWrapper, Resolvable where Result == _AnyResolvedCommandLineToolInvocationArgument, Context == _CommandLineToolResolutionContext {
    
}
