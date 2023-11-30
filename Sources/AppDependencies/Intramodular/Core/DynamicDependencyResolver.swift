//
// Copyright (c) Vatsal Manot
//

import Swallow

/// **WIP**.
public protocol DynamicDependencyResolver {
    func resolve(
        into dependencies: inout Dependencies,
        context: DynamicDependencyResolutionContext
    )
}

/// **WIP**.
public struct DynamicDependencyResolutionContext {
    
}
