//
// Copyright (c) Vatsal Manot
//


import Foundation
import Collections
import OrderedCollections
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
}
