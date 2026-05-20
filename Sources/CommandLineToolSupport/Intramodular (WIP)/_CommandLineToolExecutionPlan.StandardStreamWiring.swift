//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Foundation
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
            try validateReferencedStagesExist()
            try validateEndpointDirections()
            try validateExclusiveEndpoints()
            try validateAcyclicStageWalk()
            try validateRepeatedExclusiveStreamEffects()
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

extension _CommandLineToolExecutionPlan.StandardStreamWiring {
    public struct Stage: Identifiable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable, Sendable {
        public typealias ID = UUID

        public var id: ID
        public var role: Role
        public var commandName: String
        public var invocation: CommandLineToolInvocation?
        public var streamEffects: Set<_CommandLineToolOutputFormatterTool_Semantics.StreamEffect>

        public init(
            id: ID = ID(),
            role: Role,
            commandName: String,
            invocation: CommandLineToolInvocation? = nil,
            streamEffects: Set<_CommandLineToolOutputFormatterTool_Semantics.StreamEffect> = []
        ) {
            self.id = id
            self.role = role
            self.commandName = commandName
            self.invocation = invocation
            self.streamEffects = streamEffects
        }

        public var description: String {
            commandName
        }

        public var debugDescription: String {
            "Stage(id: \(id), role: \(role), commandName: \(String(reflecting: commandName)), streamEffects: \(streamEffects))"
        }

        public var customMirror: Mirror {
            Mirror(
                self,
                children: [
                    "id": id,
                    "role": role,
                    "commandName": commandName,
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
}

extension _CommandLineToolExecutionPlan.StandardStreamWiring {
    private func validateReferencedStagesExist() throws {
        for connection in streamConnections {
            guard stages[id: connection.output.stageID] != nil else {
                throw ValidationError.missingStage(connection.output.stageID)
            }

            guard stages[id: connection.input.stageID] != nil else {
                throw ValidationError.missingStage(connection.input.stageID)
            }
        }
    }

    private func validateEndpointDirections() throws {
        for connection in streamConnections {
            guard connection.output.stream != .standardInput else {
                throw ValidationError.invalidOutputEndpoint(connection.output)
            }

            guard connection.input.stream == .standardInput else {
                throw ValidationError.invalidInputEndpoint(connection.input)
            }
        }
    }

    private func validateExclusiveEndpoints() throws {
        var inputs: Set<StreamEndpoint> = []
        var outputs: Set<StreamEndpoint> = []

        for connection in streamConnections {
            guard inputs.insert(connection.input).inserted else {
                throw ValidationError.multipleConnectionsToInput(connection.input)
            }

            guard outputs.insert(connection.output).inserted else {
                throw ValidationError.multipleConnectionsFromOutput(connection.output)
            }
        }
    }

    private func validateAcyclicStageWalk() throws {
        let outgoingConnections = Dictionary(grouping: streamConnections, by: \.output.stageID)

        for stage in stages {
            try validateAcyclicStageWalk(
                from: stage.id,
                outgoingConnections: outgoingConnections,
                activePath: []
            )
        }
    }

    private func validateAcyclicStageWalk(
        from stageID: Stage.ID,
        outgoingConnections: [Stage.ID: [StreamConnection]],
        activePath: [Stage.ID]
    ) throws {
        guard !activePath.contains(stageID) else {
            throw ValidationError.cycleDetected(activePath + [stageID])
        }

        for connection in outgoingConnections[stageID] ?? [] {
            try validateAcyclicStageWalk(
                from: connection.input.stageID,
                outgoingConnections: outgoingConnections,
                activePath: activePath + [stageID]
            )
        }
    }

    private func validateRepeatedExclusiveStreamEffects() throws {
        let incomingStageIDs = Set(streamConnections.map(\.input.stageID))
        let rootStages = stages.filter { !incomingStageIDs.contains($0.id) }

        for stage in rootStages.isEmpty ? stages.map({ $0 }) : rootStages {
            try validateRepeatedExclusiveStreamEffects(
                from: stage.id,
                seenExclusiveEffects: [:]
            )
        }
    }

    private func validateRepeatedExclusiveStreamEffects(
        from stageID: Stage.ID,
        seenExclusiveEffects: [_CommandLineToolOutputFormatterTool_Semantics.StreamEffect.Key: Stage.ID]
    ) throws {
        guard let stage = stages[id: stageID] else {
            throw ValidationError.missingStage(stageID)
        }

        var seenExclusiveEffects = seenExclusiveEffects

        for effect in stage.streamEffects where effect.composition == .exclusive {
            if let firstStage = seenExclusiveEffects[effect.key] {
                throw ValidationError.duplicateExclusiveStreamEffect(
                    effect.key,
                    firstStage: firstStage,
                    secondStage: stage.id
                )
            }

            seenExclusiveEffects[effect.key] = stage.id
        }

        for connection in streamConnections where connection.output.stageID == stageID {
            try validateRepeatedExclusiveStreamEffects(
                from: connection.input.stageID,
                seenExclusiveEffects: seenExclusiveEffects
            )
        }
    }
}

#endif
