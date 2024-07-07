//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public protocol _ObservableTaskGroupType: _CancellablesProviding, ObservableObject {
    typealias TaskHistory = [TaskStatusDescription]
    
    associatedtype Key
    
    subscript(customIdentifier identifier: Key) -> IdentifierIndexingArrayOf<OpaqueObservableTask> { get }
    
    func cancelAll()
    
    func _opaque_lastStatus(
        forCustomTaskIdentifier identifier: AnyHashable
    ) throws -> TaskStatusDescription?
}

public class _AnyObservableTaskGroup: ObservableObject {
    
}

// MARK: - Internal

extension _ObservableTaskGroup {
    @MainActor(unsafe)
    public func _opaque_lastStatus(
        forCustomTaskIdentifier identifier: AnyHashable
    ) throws -> TaskStatusDescription? {
        self.lastStatus(forCustomTaskIdentifier: try cast(identifier.base, to: Key.self))
    }
}
