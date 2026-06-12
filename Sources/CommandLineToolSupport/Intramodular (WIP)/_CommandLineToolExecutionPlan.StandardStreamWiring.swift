//
// Copyright (c) Vatsal Manot
//


import Foundation
import OrderedCollections
import ShellScripting
import Swallow

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _CommandLineToolExecutionPlan {
    /// Provisional metadata describing how standard streams are wired for an execution plan.
    public struct StandardStreamWiring: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
        public var stages: IdentifierIndexingArrayOf<Stage>
        public var streamConnections: [StreamConnection]

        public init(
            stages: IdentifierIndexingArrayOf<Stage> = [],
            streamConnections: [StreamConnection] = []
        ) {
            self.stages = stages
            self.streamConnections = streamConnections
        }

        public func validate() throws {
            try Validator(wiring: self).validate()
        }

        public var description: String {
            streamConnections.map(\.description).joined(separator: ", ")
        }

        public var debugDescription: String {
            "_CommandLineToolExecutionPlan.StandardStreamWiring(stages: \(stages.count), streamConnections: \(streamConnections.count))"
        }

        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "stages": stages,
                    "streamConnections": streamConnections
                ],
                displayStyle: .struct
            )
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _CommandLineToolExecutionPlan.StandardStreamWiring {
    public struct Stage: Identifiable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
        public typealias ID = UUID

        public var id: ID
        public var role: Role
        public var commandName: String
        public var executionSource: _CommandLineToolExecutionSource?
        public var invocation: CommandLineToolInvocation?
        public var streamEffects: OrderedSet<_CommandLineToolOutputFormatterTool_Semantics.StreamEffect>

        public init(
            id: ID = ID(),
            role: Role,
            commandName: String,
            executionSource: _CommandLineToolExecutionSource? = nil,
            invocation: CommandLineToolInvocation? = nil,
            streamEffects: OrderedSet<_CommandLineToolOutputFormatterTool_Semantics.StreamEffect> = []
        ) {
            self.id = id
            self.role = role
            self.commandName = commandName
            self.executionSource = executionSource
            self.invocation = invocation
            self.streamEffects = streamEffects
        }

        public init(
            id: ID = ID(),
            role: Role,
            executionSource: _CommandLineToolExecutionSource,
            streamEffects: OrderedSet<_CommandLineToolOutputFormatterTool_Semantics.StreamEffect> = []
        ) {
            self.init(
                id: id,
                role: role,
                commandName: executionSource.invocation?.commandName ?? executionSource.commandLine,
                executionSource: executionSource,
                invocation: executionSource.invocation,
                streamEffects: streamEffects
            )
        }

        public var description: String {
            commandName
        }

        public var debugDescription: String {
            "Stage(id: \(id), role: \(role), commandName: \(String(reflecting: commandName)), executionSource: \(String(reflecting: executionSource)), streamEffects: \(streamEffects))"
        }

        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "id": id,
                    "role": role,
                    "commandName": commandName,
                    "executionSource": executionSource as Any,
                    "invocation": invocation as Any,
                    "streamEffects": streamEffects
                ],
                displayStyle: .struct
            )
        }
    }

    public enum Role: Hashable, Sendable {
        case primaryInvocation
        case selectedTool
        case outputFormatterTool
        case envelopingTool
        case external
    }

    public enum StandardStream: String, Hashable, Sendable {
        case standardInput
        case standardOutput
        case standardError
    }

    public struct StreamEndpoint: CustomStringConvertible, CustomDebugStringConvertible, Hashable, Sendable {
        public var stageID: Stage.ID
        public var stream: StandardStream

        public init(
            stageID: Stage.ID,
            stream: StandardStream
        ) {
            self.stageID = stageID
            self.stream = stream
        }

        public var description: String {
            "\(stageID).\(stream.rawValue)"
        }

        public var debugDescription: String {
            "StreamEndpoint(stageID: \(stageID), stream: .\(stream.rawValue))"
        }
    }

    public struct StreamConnection: CustomStringConvertible, CustomDebugStringConvertible, Hashable, Sendable {
        public var output: StreamEndpoint
        public var input: StreamEndpoint

        public init(
            output: StreamEndpoint,
            input: StreamEndpoint
        ) {
            self.output = output
            self.input = input
        }

        public var description: String {
            "\(output) -> \(input)"
        }

        public var debugDescription: String {
            "StreamConnection(output: \(output.debugDescription), input: \(input.debugDescription))"
        }
    }

    public enum ValidationError: CustomStringConvertible, Hashable, Sendable, Swift.Error {
        case missingStage(Stage.ID)
        case invalidOutputEndpoint(StreamEndpoint)
        case invalidInputEndpoint(StreamEndpoint)
        case multipleConnectionsToInput(StreamEndpoint)
        case multipleConnectionsFromOutput(StreamEndpoint)
        case cycleDetected([Stage.ID])
        case duplicateExclusiveStreamEffect(
            _CommandLineToolOutputFormatterTool_Semantics.StreamEffect.Key,
            firstStage: Stage.ID,
            secondStage: Stage.ID
        )

        public var description: String {
            switch self {
                case .missingStage(let id):
                    return "Standard stream wiring references missing stage \(id)."
                case .invalidOutputEndpoint(let endpoint):
                    return "Standard stream wiring cannot use \(endpoint) as a connection output."
                case .invalidInputEndpoint(let endpoint):
                    return "Standard stream wiring cannot use \(endpoint) as a connection input."
                case .multipleConnectionsToInput(let endpoint):
                    return "Standard stream wiring has multiple connections to \(endpoint)."
                case .multipleConnectionsFromOutput(let endpoint):
                    return "Standard stream wiring has multiple connections from \(endpoint)."
                case .cycleDetected(let stageIDs):
                    return "Standard stream wiring contains a cycle: \(stageIDs)."
                case .duplicateExclusiveStreamEffect(let key, let firstStage, let secondStage):
                    return "Standard stream wiring applies exclusive stream effect \(key.rawValue) more than once along one stream walk: \(firstStage), \(secondStage)."
            }
        }
    }

    public enum RenderingError: CustomStringConvertible, Hashable, Sendable, Swift.Error {
        case noRootStage
        case multipleRootStages([Stage.ID])
        case missingStage(Stage.ID)
        case missingStageExecutionSource(Stage.ID)
        case unsupportedConnection(StreamConnection)

        public var description: String {
            switch self {
                case .noRootStage:
                    return "Standard stream wiring cannot render a shell pipeline without a root stage."
                case .multipleRootStages(let stageIDs):
                    return "Standard stream wiring cannot render a single shell pipeline with multiple root stages: \(stageIDs)."
                case .missingStage(let stageID):
                    return "Standard stream wiring cannot render a shell pipeline because stage \(stageID) is missing."
                case .missingStageExecutionSource(let stageID):
                    return "Standard stream wiring cannot render a shell pipeline because stage \(stageID) has no execution source."
                case .unsupportedConnection(let connection):
                    return "Standard stream wiring cannot render connection \(connection) as a POSIX shell pipeline."
            }
        }
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _CommandLineToolExecutionPlan.StandardStreamWiring.Stage {
    public func renderedShellCommandString(
        using renderer: CommandLineToolInvocation.CommandLineRenderer = .posixShellCommandLine
    ) -> _ShellCommandString? {
        if let executionSource {
            switch executionSource {
                case .modeledInvocation(let invocation):
                    return invocation.renderedShellCommandString(using: renderer)
                case .shellCommandString(let commandString):
                    return commandString
            }
        }

        return invocation?.renderedShellCommandString(using: renderer)
    }
}

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _CommandLineToolExecutionPlan.StandardStreamWiring {
    public func renderedShellPipelineCommandString(
        mergingStandardErrorIntoStandardOutputAt stageID: Stage.ID? = nil,
        using renderer: CommandLineToolInvocation.CommandLineRenderer = .posixShellCommandLine
    ) throws -> _ShellCommandString {
        try validate()

        if let stageID, stages[id: stageID] == nil {
            throw RenderingError.missingStage(stageID)
        }

        let incomingStageIDs = Set(streamConnections.map(\.input.stageID))
        let rootStages = stages.filter { !incomingStageIDs.contains($0.id) }
        let outgoingConnections = Dictionary(grouping: streamConnections, by: \.output.stageID)

        guard let rootStage = rootStages.first else {
            throw RenderingError.noRootStage
        }

        guard rootStages.count == 1 else {
            throw RenderingError.multipleRootStages(rootStages.map(\.id))
        }

        var currentStageID = rootStage.id
        var renderedCommands: [String] = []

        while true {
            guard let stage = stages[id: currentStageID] else {
                throw RenderingError.missingStage(currentStageID)
            }

            guard let commandString = stage.renderedShellCommandString(using: renderer) else {
                throw RenderingError.missingStageExecutionSource(currentStageID)
            }

            renderedCommands.append(
                currentStageID == stageID
                ? "\(commandString.rawValue) 2>&1"
                : commandString.rawValue
            )

            let outgoingConnections = outgoingConnections[currentStageID] ?? []

            guard let connection = outgoingConnections.first else {
                break
            }

            guard outgoingConnections.count == 1, connection.output.stream == .standardOutput else {
                throw RenderingError.unsupportedConnection(connection)
            }

            currentStageID = connection.input.stageID
        }

        return _ShellCommandString(
            rawValue: renderedCommands.joined(separator: " | "),
            dialect: .posix
        )
    }
}
