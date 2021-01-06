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
    
    @usableFromInline
    @Published var idToStatusesMap: [AnyHashable: [TaskStatusDescription]] = [:]
    @usableFromInline
    @Published var idToTaskMap: [AnyHashable: _opaque_Task] = [:]
    @usableFromInline
    @Published var nameToLastIDMap: [TaskName: AnyHashable] = [:]
    
    public init(parent: TaskPipeline? = nil) {
        self.parent = parent
    }
    
    @usableFromInline
    func updateState<T: TaskProtocol>(for task: T) {
        DispatchQueue.asyncOnMainIfNecessary {
            if task.status.isTerminal {
                self.idToStatusesMap[task.id, default: []].append(task.statusDescription)
                self.idToTaskMap.removeValue(forKey: task.id)
            } else {
                self.idToTaskMap[task.id] = task
            }
            
            self.objectWillChange.send()
        }
    }
}

extension TaskPipeline {
    public func track<T: TaskProtocol>(_ task: T) {
        guard idToTaskMap[task.id] == nil else {
            return
        }
        
        idToTaskMap[task.id] = task
        nameToLastIDMap[task.name] = task.id
        
        task.then({ [weak task] in task.map(self.updateState) })
            .subscribe(in: cancellables)
    }
    
    @inlinable
    public subscript(_ name: TaskName) -> AnyTask<Any, Swift.Error>? {
        idToTaskMap[name].map(AnyTask.init(_opaque:))
    }
    
    @inlinable
    public func lastStatus(for taskName: TaskName) -> TaskStatusDescription? {
        guard let lastID = nameToLastIDMap[taskName] else {
            return nil
        }
        
        return idToStatusesMap[lastID]?.last
    }
    
    @inlinable
    public func cancel(_ taskName: TaskName) {
        idToTaskMap[taskName]?.cancel()
    }
    
    @inlinable
    public func cancelAllTasks() {
        idToTaskMap.values.forEach({ $0.cancel() })
    }
}

// MARK: - Auxiliary Implementation -

extension EnvironmentValues {
    @usableFromInline
    struct TaskPipelineEnvironmentKey: SwiftUI.EnvironmentKey {
        public static let defaultValue = TaskPipeline()
    }
    
    @inlinable
    public var taskPipeline: TaskPipeline {
        get {
            self[TaskPipelineEnvironmentKey]
        } set {
            self[TaskPipelineEnvironmentKey] = newValue
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
