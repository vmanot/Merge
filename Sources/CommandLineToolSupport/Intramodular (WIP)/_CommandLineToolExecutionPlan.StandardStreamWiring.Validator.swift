//
// Copyright (c) Vatsal Manot
//

import Foundation
import Collections
import OrderedCollections

@available(macOS 11.0, *)
@available(iOS, unavailable)
@available(macCatalyst, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension _CommandLineToolExecutionPlan.StandardStreamWiring {
    package struct Validator {
        package var wiring: _CommandLineToolExecutionPlan.StandardStreamWiring

        package init(
            wiring: _CommandLineToolExecutionPlan.StandardStreamWiring
        ) {
            self.wiring = wiring
        }

        package func validate() throws {
            try validateReferencedStagesExist()
            try validateEndpointDirections()
            try validateExclusiveEndpoints()
            try validateAcyclicStageWalk()
            try validateRepeatedExclusiveStreamEffects()
        }

        private func validateReferencedStagesExist() throws {
            for connection in wiring.streamConnections {
                guard wiring.stages[id: connection.output.stageID] != nil else {
                    throw ValidationError.missingStage(connection.output.stageID)
                }

                guard wiring.stages[id: connection.input.stageID] != nil else {
                    throw ValidationError.missingStage(connection.input.stageID)
                }
            }
        }

        private func validateEndpointDirections() throws {
            for connection in wiring.streamConnections {
                guard connection.output.stream != .standardInput else {
                    throw ValidationError.invalidOutputEndpoint(connection.output)
                }

                guard connection.input.stream == .standardInput else {
                    throw ValidationError.invalidInputEndpoint(connection.input)
                }
            }
        }

        private func validateExclusiveEndpoints() throws {
            var inputs: OrderedSet<StreamEndpoint> = []
            var outputs: OrderedSet<StreamEndpoint> = []

            for connection in wiring.streamConnections {
                guard inputs.append(connection.input).inserted else {
                    throw ValidationError.multipleConnectionsToInput(connection.input)
                }

                guard outputs.append(connection.output).inserted else {
                    throw ValidationError.multipleConnectionsFromOutput(connection.output)
                }
            }
        }

        private func validateAcyclicStageWalk() throws {
            var outgoingConnections: OrderedDictionary<Stage.ID, [StreamConnection]> = [:]

            for connection in wiring.streamConnections {
                outgoingConnections[connection.output.stageID, default: []].append(connection)
            }

            for stage in wiring.stages {
                try validateAcyclicStageWalk(
                    from: stage.id,
                    outgoingConnections: outgoingConnections,
                    activePath: []
                )
            }
        }

        private func validateAcyclicStageWalk(
            from stageID: Stage.ID,
            outgoingConnections: OrderedDictionary<Stage.ID, [StreamConnection]>,
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
            let incomingStageIDs = OrderedSet(wiring.streamConnections.map(\.input.stageID))
            let rootStages = wiring.stages.filter { !incomingStageIDs.contains($0.id) }

            for stage in rootStages.isEmpty ? wiring.stages.map({ $0 }) : rootStages {
                try validateRepeatedExclusiveStreamEffects(
                    from: stage.id,
                    seenExclusiveEffects: [:]
                )
            }
        }

        private func validateRepeatedExclusiveStreamEffects(
            from stageID: Stage.ID,
            seenExclusiveEffects: OrderedDictionary<_CommandLineToolOutputFormatterTool_Semantics.StreamEffect.Key, Stage.ID>
        ) throws {
            guard let stage = wiring.stages[id: stageID] else {
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

            for connection in wiring.streamConnections where connection.output.stageID == stageID {
                try validateRepeatedExclusiveStreamEffects(
                    from: connection.input.stageID,
                    seenExclusiveEffects: seenExclusiveEffects
                )
            }
        }
    }
}
