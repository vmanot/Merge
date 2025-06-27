//
// Copyright (c) Vatsal Manot
//

import SwiftUI

extension View {
    /// Supplies a task pipeline to a view subhierachy.
    public func _observableTaskGroup<T: _ObservableTaskGroupType>(
        _ value: T
    ) -> some View {
        environment(\._observableTaskGroup, value).environmentObject(value)
    }
}

// MARK: - Auxiliary

extension EnvironmentValues {
    struct _ObservableTaskGroupKey: SwiftUI.EnvironmentKey {
        static let defaultValue: (any _ObservableTaskGroupType)? = nil
    }
    
    public var _observableTaskGroup: (any _ObservableTaskGroupType)? {
        get {
            self[_ObservableTaskGroupKey.self]
        }
        set {
            self[_ObservableTaskGroupKey.self] = newValue
        }
    }
}
