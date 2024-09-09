//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A type that exports some set of dependencies.
///
/// These exported dependencies are consumed in operations such as `withTaskDependencies(from: ...) { ... }` etc.
public protocol _TaskDependenciesExporting {
    var _exportedTaskDependencies: TaskDependencies { get }
}
