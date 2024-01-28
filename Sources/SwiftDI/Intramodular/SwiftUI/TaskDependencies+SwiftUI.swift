//
// Copyright (c) Vatsal Manot
//

import SwiftUI

extension EnvironmentValues {
    fileprivate struct _TaskDependenciesKey: EnvironmentKey {
        static let defaultValue = TaskDependencies()
    }
    
    var _dependencies: TaskDependencies {
        get {
            self[_TaskDependenciesKey.self]
        } set {
            self[_TaskDependenciesKey.self] = newValue
        }
    }
}

extension View {
    public func dependencies(
        _ dependencies: Dependencies
    ) -> some View {
        transformEnvironment(\._dependencies) {
            $0.mergeInPlace(with: dependencies)
        }
    }
    
    public func dependency<V>(
        _ key: WritableKeyPath<TaskDependencyValues, V>,
        _ value: V
    ) -> some View {
        transformEnvironment(\._dependencies) {
            $0[key] = value
        }
    }
}

public func withDependencies<Subject, Content: View>(
    from subject: Subject,
    @ViewBuilder content: () -> Content
) -> some View {
    var result: Content!
    
    withDependencies(from: subject) {
        result = content()
    }
    
    return result
}
