//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift
import SwiftUI

public final class TaskPipeline: CancellablesHolder, ObservableObject {
    public enum Error: Swift.Error {
        
    }
    
    public let cancellables = Cancellables()
    
    private weak var parent: TaskPipeline?
    
    public var tasks: [OpaqueTask]  {
        .init(idToTaskMap.values)
    }
    
    @usableFromInline
    @Published var idToStatusesMap: [AnyHashable: [TaskStatusDescription]] = [:]
    @usableFromInline
    @Published var idToTaskMap: [AnyHashable: OpaqueTask] = [:]
    @usableFromInline
    @Published var taskIDToIDMap: [TaskIdentifier: AnyHashable] = [:]
    
    public init(parent: TaskPipeline? = nil) {
        self.parent = parent
    }
    
    @usableFromInline
    func updateState<T: Task>(for task: T) {
        DispatchQueue.asyncOnMainIfNecessary {
            if task.status.isTerminal {
                self.idToStatusesMap[task.id, default: []].append(task.statusDescription)
                self.idToTaskMap.removeValue(forKey: task.id)
            } else {
                self.idToTaskMap[task.id] = .init(task)
            }
            
            self.objectWillChange.send()
        }
    }
}

extension TaskPipeline {
    public func track<T: Task>(_ task: T) {
        guard idToTaskMap[task.id] == nil else {
            return
        }
        
        idToTaskMap[task.id] = .init(task)
        taskIDToIDMap[task.taskIdentifier] = task.id
        
        task.then({ [weak task] in task.map(self.updateState) })
            .subscribe(in: cancellables)
    }
    
    @inlinable
    public subscript(_ name: TaskIdentifier) -> AnyTask<Any, Swift.Error>? {
        taskIDToIDMap[name].flatMap({ idToTaskMap[$0] }).map(AnyTask.init(_opaque:))
    }
    
    @inlinable
    public func lastStatus(for taskName: TaskIdentifier) -> TaskStatusDescription? {
        guard let lastID = taskIDToIDMap[taskName] else {
            return nil
        }
        
        return idToStatusesMap[lastID]?.last
    }
    
    @inlinable
    public func cancel(_ taskName: TaskIdentifier) {
        idToTaskMap[taskName]?.cancel()
    }
    
    @inlinable
    public func cancelAllTasks() {
        idToTaskMap.values.forEach({ $0.cancel() })
    }
}

// MARK: - Auxiliary Implementation -

extension TaskPipeline {
    @usableFromInline
    struct EnvironmentKey: SwiftUI.EnvironmentKey {
        public static let defaultValue = TaskPipeline()
    }
}

extension EnvironmentValues {
    @inlinable
    public var taskPipeline: TaskPipeline {
        get {
            self[TaskPipeline.EnvironmentKey]
        } set {
            self[TaskPipeline.EnvironmentKey] = newValue
        }
    }
}

// MARK: - API -

extension View {
    @inlinable
    public func taskPipeline(_ pipeline: TaskPipeline) -> some View {
        self.environment(\.taskPipeline, pipeline)
            .environmentObject(pipeline)
    }
}
