//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Swallow
import SwiftUI

public protocol _ObservableTaskGraph_Type: ObservableObject {
    associatedtype TaskID
    
    subscript(customTaskIdentifier identifier: TaskID) -> OpaqueObservableTask? { get }
}

public class _AnyObservableTaskGraph: ObservableObject {
    open func _opaque_lastStatus(
        forCustomTaskIdentifier identifier: AnyHashable
    ) throws -> TaskStatusDescription? {
        fatalError()
    }
}

public final class _ObservableTaskGraph<TaskID: Hashable>: _AnyObservableTaskGraph, CancellablesHolder, _ObservableTaskGraph_Type {
    typealias TaskHistory = [TaskStatusDescription]
     
    public let cancellables = Cancellables()
    
    private weak var parent: _ObservableTaskGraph?
    
    public var tasks: [OpaqueObservableTask]  {
        .init(idToTaskMap.values)
    }
    
    @Published var idToTaskMap: [AnyHashable: OpaqueObservableTask] = [:]
    @Published var idToCustomTaskIdentifierMap: [AnyHashable: TaskID] = [:]
    @Published var customTaskIdentifierToIDMap: [TaskID: AnyHashable] = [:]
    @Published var customTaskIdentifierToStatusHistoryMap: [TaskID: TaskHistory] = [:]

    public init(parent: _ObservableTaskGraph? = nil) {
        self.parent = parent
    }
    
    public init(parent: _ObservableTaskGraph? = nil) where TaskID == AnyHashable {
        self.parent = parent
    }
    
    override public func _opaque_lastStatus(
        forCustomTaskIdentifier identifier: AnyHashable
    ) throws -> TaskStatusDescription? {
        self.lastStatus(forCustomTaskIdentifier: try cast(identifier.base, to: TaskID.self))
    }
}

extension _ObservableTaskGraph: Sequence {
    public struct Element {
        public let taskID: AnyHashable?
        public let customTaskIdentifier: TaskID?
        public let status: TaskStatusDescription?
        public let history: [TaskStatusDescription]
    }
    
    public func makeIterator() -> AnyIterator<Element> {
        let deadTasks: Set<TaskID> = Set(customTaskIdentifierToStatusHistoryMap.keys).subtracting(Set(customTaskIdentifierToIDMap.keys))
         
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
        withCustomIdentifier customTaskIdentifier: TaskID?
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
                self.idToTaskMap.removeValue(forKey: task.id)

                _expectedToNotThrow {
                    let taskID = try self.idToCustomTaskIdentifierMap[task.id].unwrap()
                    
                    self.customTaskIdentifierToStatusHistoryMap[taskID, default: []].append(task.statusDescription)
                    self.idToCustomTaskIdentifierMap.removeValue(forKey: task.id)
                    self.customTaskIdentifierToIDMap.removeValue(forKey: taskID)
                }
            } else {
                self.idToTaskMap[task.id] = .init(erasing: task)
            }
        }
    }
    
    public subscript(customTaskIdentifier identifier: TaskID) -> OpaqueObservableTask? {
        customTaskIdentifierToIDMap[identifier]
            .flatMap({ idToTaskMap[$0] })
    }
    
    public func lastStatus(
        forCustomTaskIdentifier identifier: TaskID
    ) -> TaskStatusDescription? {
        customTaskIdentifierToStatusHistoryMap[identifier]?.last
    }
    
    public func cancelAllTasks() {
        idToTaskMap.values.forEach({ $0.cancel() })
    }
}

extension _ObservableTaskGraph {    
    public func status(of action: TaskID) -> TaskStatusDescription {
        self[customTaskIdentifier: action]?.statusDescription ?? .idle
    }
    
    private func _customTaskID<T>(
        ofMostRecent casePath: CasePath<TaskID, T>
    ) throws -> TaskID?  {
        guard let element = try firstAndOnly(where: {
            guard let customTaskIdentifier = $0.customTaskIdentifier else {
                return false
            }
            
            return try casePath._opaque_extract(from: customTaskIdentifier) != nil
        }) else {
            return nil
        }
        
        return element.customTaskIdentifier
    }
    
    public func status(
        ofMostRecent action: TaskID
    ) -> TaskStatusDescription? {
        _expectedToNotThrow {
            if let status = self[customTaskIdentifier: action]?.statusDescription {
                return status
            } else {
                return lastStatus(forCustomTaskIdentifier: action)
            }
        }
    }
    
    public func status<T>(
        ofMostRecent casePath: CasePath<TaskID, T>
    ) -> TaskStatusDescription? {
        return _expectedToNotThrow { () -> TaskStatusDescription? in
            guard let id  = try _customTaskID(ofMostRecent: casePath) else {
                return nil
            }
            
            if let status = self[customTaskIdentifier: id]?.statusDescription {
                return status
            } else {
                return lastStatus(forCustomTaskIdentifier: id)
            }
        }
    }
        
    public func cancel(task: TaskID) {
        _expectedToNotThrow {
           try self[customTaskIdentifier: task].unwrap().cancel()
        }
    }
}

// MARK: - SwiftUI API -

extension View {
    /// Supplies a task pipeline to a view subhierachy.
    public func _taskGraph<T: _ObservableTaskGraph_Type>(_ graph: T) -> some View {
        environment(\._taskGraph, graph).environmentObject(graph)
    }
}

extension EnvironmentValues {
    struct _ObservableTaskGraphKey: SwiftUI.EnvironmentKey {
        static let defaultValue: (any _ObservableTaskGraph_Type)? = nil
    }
    
    public var _taskGraph: (any _ObservableTaskGraph_Type)? {
        get {
            self[_ObservableTaskGraphKey.self]
        } set {
            self[_ObservableTaskGraphKey.self] = newValue
        }
    }
}
