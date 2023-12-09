//
// Copyright (c) Vatsal Manot
//

import ObjectiveC
import Diagnostics
import Swallow

public enum DependenciesError: Error {
    case failedToResolveDependency(Any.Type)
    case failedToUseDependencies(Error)
}
