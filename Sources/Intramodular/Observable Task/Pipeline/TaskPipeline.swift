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
    
    @Published var idToTaskMap: [AnyHashable: OpaqueTask] = [:]
    @Published var taskIDToIDMap: [TaskIdentifier: AnyHashable] = [:]
    @Published var taskIDToStatusesMap: [TaskIdentifier: [TaskStatusDescription]] = [:]
    
    public init(parent: TaskPipeline? = nil) {
        self.parent = parent
    }
    
    func updateState<T: ObservableTask>(for task: T) {
        DispatchQueue.asyncOnMainIfNecessary {
            if task.status.isTerminal {
                self.taskIDToStatusesMap[task.taskIdentifier, default: []].append(task.statusDescription)
                self.idToTaskMap.removeValue(forKey: task.id)
            } else {
                self.idToTaskMap[task.id] = .init(task)
            }
            
            self.objectWillChange.send()
        }
    }
}

extension TaskPipeline {
    public func track<T: ObservableTask>(_ task: T) {
        guard idToTaskMap[task.id] == nil else {
            return
        }
        
        idToTaskMap[task.id] = .init(task)
        taskIDToIDMap[task.taskIdentifier] = task.id
        
        task.statusDescriptionWillChange
            .then({ [weak task] in task.map(self.updateState) })
            .subscribe(in: cancellables)
    }
    
    public subscript(_ name: TaskIdentifier) -> AnyTask<Any, Swift.Error>? {
        taskIDToIDMap[name].flatMap({ idToTaskMap[$0] }).map(AnyTask.init(_opaque:))
    }
    
    public func lastStatus(for identifier: TaskIdentifier) -> TaskStatusDescription? {
        taskIDToStatusesMap[identifier]?.last
    }
    
    public func cancel(_ taskName: TaskIdentifier) {
        idToTaskMap[taskName]?.cancel()
    }
    
    public func cancelAllTasks() {
        idToTaskMap.values.forEach({ $0.cancel() })
    }
}

// MARK: - Auxiliary Implementation -

extension EnvironmentValues {
    struct TaskPipelineKey: SwiftUI.EnvironmentKey {
        static let defaultValue = TaskPipeline()
    }
    
    public var taskPipeline: TaskPipeline {
        get {
            self[TaskPipelineKey.self]
        } set {
            self[TaskPipelineKey.self] = newValue
        }
    }
}

// MARK: - API -

extension View {
    /// Supplies a task pipeline to a view subhierachy.
    public func taskPipeline(_ pipeline: TaskPipeline) -> some View {
        environment(\.taskPipeline, pipeline).environmentObject(pipeline)
    }
}
