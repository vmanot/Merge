//
// Copyright (c) Vatsal Manot
//

import Swift

public enum _TaskDependencyKind {
    case parameter
    case contextual
}

@_spi(Internal)
public protocol _DependencyPropertyWrapperScope {
    
}

public enum _TaskDependencyAttribute {
    case unstashable
}

extension TaskDependencyKey {
    public static var attributes: Set<_TaskDependencyAttribute> {
        []
    }
}
