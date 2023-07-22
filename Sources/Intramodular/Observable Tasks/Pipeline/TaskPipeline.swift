//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift
import SwiftUI

public final class _ObservableTaskGraph: CancellablesHolder, ObservableObject {
    typealias TaskHistory = [TaskStatusDescription]
     
    public let cancellables = Cancellables()
    
    private weak var parent: _ObservableTaskGraph?
    
    public var tasks: [OpaqueObservableTask]  {
        .init(idToTaskMap.values)
    }
    
    @Published var idToTaskMap: [AnyHashable: OpaqueObservableTask] = [:]
    @Published var idToCustomTaskIdentifierMap: [AnyHashable: AnyHashable] = [:]
    @Published var customTaskIdentifierToIDMap: [AnyHashable: AnyHashable] = [:]
    @Published var customTaskIdentifierToStatusHistoryMap: [AnyHashable: TaskHistory] = [:]

    public init(parent: _ObservableTaskGraph? = nil) {
        self.parent = parent
    }
}

extension _ObservableTaskGraph: Sequence {
    public struct Element {
        public let taskID: AnyHashable?
        public let customTaskIdentifier: AnyHashable?
        public let status: TaskStatusDescription?
        public let history: [TaskStatusDescription]
    }
    
    public func makeIterator() -> AnyIterator<Element> {
        let deadTasks: Set<AnyHashable> = Set(customTaskIdentifierToStatusHistoryMap.keys).subtracting(Set(customTaskIdentifierToIDMap.keys))
         
        let active = idToTaskMap.keys.map { taskID in
            let customTaskID = self.idToCustomTaskIdentifierMap[taskID]
            
            return Element(
                taskID: taskID,
                customTaskIdentifier: customTaskID,
                status: self.idToTaskMap[taskID]?.statusDescription,
                history: customTaskID.flatMap({ self.customTaskIdentifierToStatusHistoryMap[$0] }) ?? .init()
            )
        }

        let tombstoned = deadTasks.map { customTaskID in
            return Element(
                taskID: nil,
                customTaskIdentifier: customTaskID,
                status: nil,
                history: self.customTaskIdentifierToStatusHistoryMap[customTaskID] ?? .init()
            )
        }
        
        return AnyIterator((active + tombstoned).makeIterator())
    }
}

extension _ObservableTaskGraph {
    public func track<T: ObservableTask>(
        _ task: T,
        withCustomIdentifier customTaskIdentifier: AnyHashable?
    ) {
        guard idToTaskMap[task.id] == nil else {
            return
        }
        
        idToTaskMap[task.id] = .init(erasing: task)
        idToCustomTaskIdentifierMap[task.id] = customTaskIdentifier
        
        if let customTaskIdentifier = customTaskIdentifier {
            idToCustomTaskIdentifierMap[task.id] = customTaskIdentifier
            customTaskIdentifierToIDMap[customTaskIdentifier] = task.id
        }
        
        task.objectDidChange
            .map({ TaskStatusDescription($0) })
            .then({ [weak task] in task.map(self.updateState) })
            .subscribe(in: cancellables)
    }
    
    
    func updateState<T: ObservableTask>(for task: T) {
        DispatchQueue.asyncOnMainIfNecessary {
            if task.status.isTerminal {
                self.customTaskIdentifierToStatusHistoryMap[task.id, default: []].append(task.statusDescription)
                self.idToTaskMap.removeValue(forKey: task.id)
                
                if let customTaskIdentifier = self.idToCustomTaskIdentifierMap[task.id] {
                    self.idToCustomTaskIdentifierMap.removeValue(forKey: task.id)
                    self.customTaskIdentifierToIDMap.removeValue(forKey: customTaskIdentifier)
                }
            } else {
                self.idToTaskMap[task.id] = .init(erasing: task)
            }
        }
    }
    
    public subscript(customTaskIdentifier identifier: AnyHashable) -> OpaqueObservableTask? {
        customTaskIdentifierToIDMap[identifier]
            .flatMap({ idToTaskMap[$0] })
    }
    
    public func lastStatus(
        forCustomTaskIdentifier identifier: AnyHashable
    ) -> TaskStatusDescription? {
        customTaskIdentifierToIDMap[identifier].flatMap({ customTaskIdentifierToStatusHistoryMap[$0]?.last })
    }
    
    public func cancelAllTasks() {
        idToTaskMap.values.forEach({ $0.cancel() })
    }
}

// MARK: - SwiftUI API -

extension View {
    /// Supplies a task pipeline to a view subhierachy.
    public func _taskGraph(_ pipeline: _ObservableTaskGraph) -> some View {
        environment(\._taskGraph, pipeline).environmentObject(pipeline)
    }
}

extension EnvironmentValues {
    struct _ObservableTaskGraphKey: SwiftUI.EnvironmentKey {
        static let defaultValue = _ObservableTaskGraph()
    }
    
    public var _taskGraph: _ObservableTaskGraph {
        get {
            self[_ObservableTaskGraphKey.self]
        } set {
            self[_ObservableTaskGraphKey.self] = newValue
        }
    }
}
