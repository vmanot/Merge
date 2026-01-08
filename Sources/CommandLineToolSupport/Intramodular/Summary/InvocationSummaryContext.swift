//
//  InvocationSummaryContext.swift
//  Merge
//

import Foundation

public struct InvocationSummaryContext<Command: AnyCommandLineTool> {
    public let command: Command
    public let parent: AnyCommandLineTool?
    private let emissionState: InvocationSummaryEmissionState

    public private(set) var emittedArguments: Set<_ResolvedCommandLineToolDescription.ArgumentID> {
        get {
            emissionState.emittedArguments
        }
        set {
            emissionState.emittedArguments = newValue
        }
    }

    public init(command: Command, parent: AnyCommandLineTool?) {
        self.command = command
        self.parent = parent
        self.emissionState = InvocationSummaryEmissionState()
    }
    
    init(command: Command, parent: AnyCommandLineTool?, emissionState: InvocationSummaryEmissionState) {
        self.command = command
        self.parent = parent
        self.emissionState = emissionState
    }

    public func parent<Parent: AnyCommandLineTool>(of type: Parent.Type = Parent.self) -> Parent? {
        var current = parent

        while let candidate = current {
            if let typed = candidate as? Parent {
                return typed
            }

            if let subcommand = candidate as? any _GenericSubcommandProtocol {
                if let command = subcommand.command as? Parent {
                    return command
                }

                current = subcommand.parent
                continue
            }

            break
        }

        return nil
    }
    
    func sharingEmissionState(
        command: Command,
        parent: AnyCommandLineTool?
    ) -> InvocationSummaryContext {
        InvocationSummaryContext(
            command: command,
            parent: parent,
            emissionState: emissionState
        )
    }
    
    func _hasEmitted(_ argumentID: _ResolvedCommandLineToolDescription.ArgumentID) -> Bool {
        emissionState.emittedArguments.contains(argumentID)
    }
    
    func _hasEmitted(tokens: [String]) -> Bool {
        emissionState.emittedArgumentTokens.contains(tokens)
    }
    
    func _recordEmitted(
        argumentID: _ResolvedCommandLineToolDescription.ArgumentID?,
        tokens: [String]
    ) {
        guard !tokens.isEmpty else { return }
        
        if let argumentID {
            emissionState.emittedArguments.insert(argumentID)
        }
        
        emissionState.emittedArgumentTokens.insert(tokens)
    }
}

final class InvocationSummaryEmissionState {
    var emittedArguments: Set<_ResolvedCommandLineToolDescription.ArgumentID> = []
    var emittedArgumentTokens: Set<[String]> = []
}
