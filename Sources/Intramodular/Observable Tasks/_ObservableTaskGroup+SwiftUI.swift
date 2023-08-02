//
// Copyright (c) Vatsal Manot
//

import SwiftUI

extension View {
    /// Supplies a task pipeline to a view subhierachy.
    public func _observableTaskGroup<T: _ObservableTaskGroup_Type>(
        _ value: T
    ) -> some View {
        environment(\._observableTaskGroup, value).environmentObject(value)
    }
}

// MARK: - Auxiliary

extension EnvironmentValues {
    struct _ObservableTaskGroupKey: SwiftUI.EnvironmentKey {
        static let defaultValue: (any _ObservableTaskGroup_Type)? = nil
    }
    
    public var _observableTaskGroup: (any _ObservableTaskGroup_Type)? {
        get {
            self[_ObservableTaskGroupKey.self]
        } set {
            self[_ObservableTaskGroupKey.self] = newValue
        }
    }
}
