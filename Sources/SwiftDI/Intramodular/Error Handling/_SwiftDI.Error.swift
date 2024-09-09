//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Swallow

extension _SwiftDI {
    public enum Error: Swift.Error {
        case failedToResolveDependency(Any.Type)
        case failedToConsumeDependencies(AnyError)
    }
}
