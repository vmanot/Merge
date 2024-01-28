//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A type that exports some set of dependencies.
///
/// These exported dependencies are consumed in operations such as `withDependencies(from: ...) { ... }` etc.
public protocol _TaskDependenciesExporting {
    var _exportedTaskDependencies: Dependencies { get }
}
