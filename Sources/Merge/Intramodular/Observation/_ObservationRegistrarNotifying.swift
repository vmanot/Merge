//
// Copyright (c) Vatsal Manot
//

import Combine
#if canImport(Observation)
import Observation
#endif
import Swallow

public enum _ObservationRegistrarTrackedOperationKind {
    case accessOnly
    case mutation
}

/// Adding `@Observable` to a type after importing `Observation` installs an "observation registrar".
///
/// The types implementing this protocol are expected to expose raw access to registrar-notifying operations.
public protocol _ObservationRegistrarNotifying {
    func notifyingObservationRegistrar<Result>(
        _ kind: _ObservationRegistrarTrackedOperationKind,
        perform operation: () -> Result
    ) -> Result
}
