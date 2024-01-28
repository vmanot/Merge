//
// Copyright (c) Vatsal Manot
//

import Swift

public protocol _TaskDependenciesConsuming {
    func __consume(_: TaskDependencies) throws
}
