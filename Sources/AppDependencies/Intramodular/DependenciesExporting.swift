//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A type that exports some set of dependencies.
///
/// These exported dependencies are consumed in operations such as `withDependencies(from: ...) { ... }` etc.
public protocol DependenciesExporting {
    var exportedDependencies: Dependencies { get }
}
