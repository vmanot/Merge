//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public protocol _ObservableTaskGroupType: _CancellablesProviding, ObservableObject {
    typealias TaskHistory = [ObservableTaskStatusDescription]
    
    associatedtype Key
    
    @MainActor
    subscript(customIdentifier identifier: Key) -> IdentifierIndexingArrayOf<OpaqueObservableTask> { get }
    
    func cancelAll()
    
    @MainActor
    func _opaque_lastStatus(
        forCustomTaskIdentifier identifier: AnyHashable
    ) throws -> ObservableTaskStatusDescription?
}

public class _AnyObservableTaskGroup: ObservableObject {
    
}

// MARK: - Internal

extension _ObservableTaskGroup {
    @MainActor
    public func _opaque_lastStatus(
        forCustomTaskIdentifier identifier: AnyHashable
    ) throws -> ObservableTaskStatusDescription? {
        self.lastStatus(forCustomTaskIdentifier: try cast(identifier.base, to: Key.self))
    }
}
