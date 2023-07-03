//
// Copyright (c) Vatsal Manot
//

import SwiftUI

extension EnvironmentValues {
    struct _DependenciesKey: EnvironmentKey {
        static let defaultValue = Dependencies()
    }
    
    var _dependencies: Dependencies {
        get {
            self[_DependenciesKey.self]
        } set {
            self[_DependenciesKey.self] = newValue
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
        _ key: WritableKeyPath<DependencyValues, V>,
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
