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
    
    public var tasks: [OpaqueObservableTask]  {
        .init(idToTaskMap.values)
    }
    
    @Published var idToTaskMap: [AnyHashable: OpaqueObservableTask] = [:]
    @Published var idToStatusHistoryMap: [AnyHashable: [TaskStatusDescription]] = [:]
    
    @Published var idToCustomTaskIdentifierMap: [AnyHashable: AnyHashable] = [:]
    @Published var customTaskIdentifierToIDMap: [AnyHashable: AnyHashable] = [:]

    public init(parent: TaskPipeline? = nil) {
        self.parent = parent
    }
}

extension TaskPipeline {
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
                self.idToStatusHistoryMap[task.id, default: []].append(task.statusDescription)
                self.idToTaskMap.removeValue(forKey: task.id)
                
                if let customTaskIdentifier = self.idToCustomTaskIdentifierMap[task.id] {
                    self.idToCustomTaskIdentifierMap.removeValue(forKey: task.id)
                    self.customTaskIdentifierToIDMap.removeValue(forKey: customTaskIdentifier)
                }
            } else {
                self.idToTaskMap[task.id] = .init(erasing: task)
            }
            
            self.objectWillChange.send()
        }
    }
    
    public subscript(customTaskIdentifier identifier: AnyHashable) -> AnyTask<Any, Swift.Error>? {
        customTaskIdentifierToIDMap[identifier]
            .flatMap({ idToTaskMap[$0] })
            .map(AnyTask.init(erasing:))
    }
    
    public func lastStatus(forCustomTaskIdentifier identifier: AnyHashable) -> TaskStatusDescription? {
        customTaskIdentifierToIDMap[identifier].flatMap({ idToStatusHistoryMap[$0]?.last })
    }
        
    public func cancelAllTasks() {
        idToTaskMap.values.forEach({ $0.cancel() })
    }
}

// MARK: - SwiftUI API -

extension View {
    /// Supplies a task pipeline to a view subhierachy.
    public func taskPipeline(_ pipeline: TaskPipeline) -> some View {
        environment(\.taskPipeline, pipeline).environmentObject(pipeline)
    }
}

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
