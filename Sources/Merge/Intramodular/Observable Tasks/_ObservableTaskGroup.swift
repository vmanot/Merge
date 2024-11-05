//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Dispatch
import Swallow

public final class _ObservableTaskGroup<CustomIdentifier: Hashable>: _AnyObservableTaskGroup, _ObservableTaskGroupType {
    public let cancellables = Cancellables()
    
    @_spi(Internal)
    @MainActor
    public var keepHistory: Bool = false {
        didSet {
            taskHistoriesByCustomIdentifier.removeAll()
        }
    }
    
    private weak var parent: _ObservableTaskGroup?
    
    @Published private var activeTasks: IdentifierIndexingArrayOf<OpaqueObservableTask> = []
    @Published private var customIdentifierByTask: [OpaqueObservableTask.ID: CustomIdentifier] = [:]
    @Published private var activeTasksByCustomIdentifier: [CustomIdentifier: IdentifierIndexingArrayOf<OpaqueObservableTask>] = [:]
    @Published private var taskHistoriesByCustomIdentifier: [CustomIdentifier: TaskHistory] = [:]
    
    private init(_parent parent: _ObservableTaskGroup? = nil) {
        assert(CustomIdentifier.self != OpaqueObservableTask.ID.self)
        
        self.parent = parent
    }
}

extension _ObservableTaskGroup {
    public convenience init(parent: _ObservableTaskGroup? = nil) {
        self.init(_parent: parent)
    }
    
    public convenience init(parent: _ObservableTaskGroup? = nil) where CustomIdentifier == AnyHashable {
        self.init(_parent: parent)
    }
}

extension _ObservableTaskGroup {
    @MainActor
    public func addTask<T: ObservableTask>(
        _ task: T,
        withCustomIdentifier customIdentifier: CustomIdentifier?
    ) {
        let task = task.eraseToOpaqueObservableTask()
        
        assert(task.status == .idle)
        
        guard !activeTasks.contains(task) else {
            return
        }
        
        activeTasks.append(task)
        customIdentifierByTask[task.id] = customIdentifier
        
        if let customIdentifier = customIdentifier {
            customIdentifierByTask[task.id] = customIdentifier
            activeTasksByCustomIdentifier[customIdentifier, default: []].append(task)
        }
        
        task.objectDidChange
            .then({ [weak task] in task.map(self._taskDidUpdate) })
            .subscribe(in: cancellables)
    }
    
    @MainActor
    private func _taskDidUpdate<T: ObservableTask>(
        _ task: T
    ) {
        let task = task.eraseToOpaqueObservableTask()
        
        assert(self.activeTasks.contains(task))
        
        if task.status.isTerminal {
            DispatchQueue.asyncOnMainIfNecessary {
                self.activeTasks.remove(task)
                
                #try(.optimistic) {
                    let taskID = try self.customIdentifierByTask[task.id].unwrap()
                    
                    if self.keepHistory {
                        self.taskHistoriesByCustomIdentifier[taskID, default: []].append(task.statusDescription)
                    }
                    
                    self.customIdentifierByTask.removeValue(forKey: task.id)
                    self.activeTasksByCustomIdentifier[taskID, default: []].remove(task)
                }
            }
        }
    }
    
    @MainActor
    private func _taskDidTerminate(_ task: OpaqueObservableTask) throws {
        assert(self.activeTasks.contains(task))
        
        self.activeTasks.remove(task)
        
        if let customIdentifier = self.customIdentifierByTask[task.id] {
            if keepHistory {
                self.taskHistoriesByCustomIdentifier[customIdentifier, default: []].append(task.statusDescription)
            }
            
            self.customIdentifierByTask.removeValue(forKey: task.id)
            self.activeTasksByCustomIdentifier[customIdentifier, default: []].remove(task)
        }
    }
}

@MainActor
extension _ObservableTaskGroup {
    public subscript(
        customIdentifier identifier: CustomIdentifier
    ) -> IdentifierIndexingArrayOf<OpaqueObservableTask> {
        var filtered: [OpaqueObservableTask] = []
        
        defer {
            #try(.optimistic) {
                try _tryAssert(filtered.isEmpty)
            }
        }
        
        return activeTasksByCustomIdentifier[identifier, default: []]._filter(removingInto: &filtered) {
            !$0.status.isTerminal
        }
    }
    
    public func customIdentifier(
        for task: OpaqueObservableTask
    ) -> CustomIdentifier? {
        assert(activeTasks.contains(task))
        
        return customIdentifierByTask[task.id]
    }
    
    public func tasks<T>(
        matchedBy casePath: CasePath<CustomIdentifier, T>
    ) throws -> IdentifierIndexingArrayOf<OpaqueObservableTask> {
        try IdentifierIndexingArrayOf(
            self
                .filter { (element: Element) -> Bool in
                    guard let customIdentifier = element.customIdentifier else {
                        return false
                    }
                    
                    return try casePath._opaque_extract(from: customIdentifier) != nil
                }
                .compactMap({ $0.source?.wrappedValue })
        )
    }
    
    public func lastStatus(
        forCustomTaskIdentifier identifier: CustomIdentifier
    ) -> ObservableTaskStatusDescription? {
        guard keepHistory else {
            assertionFailure()
            
            return nil
        }
        
        return taskHistoriesByCustomIdentifier[identifier]?.last
    }
    
    public nonisolated func cancelAll() {
        Task { @MainActor in
            activeTasks.forEach({ $0.cancel() })
        }
    }
}

extension _ObservableTaskGroup {
    @MainActor
    private func _customIdentifier<T>(
        ofMostRecent casePath: CasePath<Key, T>
    ) throws -> Key?  {
        guard let element = try firstAndOnly(where: {
            guard let customIdentifier = $0.customIdentifier else {
                return false
            }
            
            return try casePath._opaque_extract(from: customIdentifier) != nil
        }) else {
            return nil
        }
        
        return element.customIdentifier
    }
    
    @MainActor
    public func status(
        ofMostRecent action: Key
    ) -> ObservableTaskStatusDescription? {
        if let status = self[customIdentifier: action].last?.statusDescription {
            return status
        } else {
            return self.lastStatus(forCustomTaskIdentifier: action)
        }
    }
    
    @MainActor
    public func status<T>(
        ofMostRecent casePath: CasePath<Key, T>
    ) -> ObservableTaskStatusDescription? {
        return #try(.optimistic) { () -> ObservableTaskStatusDescription? in
            guard let id  = try _customIdentifier(ofMostRecent: casePath) else {
                return nil
            }
            
            if let status = self[customIdentifier: id].last?.statusDescription {
                return status
            } else {
                return lastStatus(forCustomTaskIdentifier: id)
            }
        }
    }
    
    @MainActor
    public func cancelAll(identifiedBy key: Key) {
        self[customIdentifier: key].forEach({ $0.cancel() })
    }
}

// MARK: - Conformances

extension _ObservableTaskGroup: Sequence {
    /// A snapshot of an active/tombstoned task in the group.
    public struct Element {
        fileprivate var source: Weak<OpaqueObservableTask>?
        
        public let customIdentifier: Key?
        public let status: ObservableTaskStatusDescription?
        public let history: TaskHistory
        
        public init(
            source: OpaqueObservableTask?,
            customIdentifier: Key?,
            history: TaskHistory?
        ) {
            self.source = source.map(Weak.init(wrappedValue:))
            self.customIdentifier = customIdentifier
            self.status = source?.statusDescription
            self.history = history ?? []
        }
        
        public var taskID: OpaqueObservableTask.ID? {
            guard let source else {
                return nil
            }
            
            assert(source.wrappedValue != nil)
            
            return source.wrappedValue?.id
        }
    }
    
    public func makeIterator() -> AnyIterator<Element> {
        let allKnownCustomIdentifiers: Set<CustomIdentifier> = Set(taskHistoriesByCustomIdentifier.keys)
        let activeCustomIdentifiers: Set<CustomIdentifier>  = Set(activeTasksByCustomIdentifier.lazy.filter({ !$0.value.isEmpty }).map(\.key))
        let tomstonedCustomIdentifiers: Set<CustomIdentifier> = allKnownCustomIdentifiers.subtracting(activeCustomIdentifiers)
        
        let active: [Element] = activeTasks.map { task in
            let identifier = self.customIdentifierByTask[task.id]
            
            return Element(
                source: task,
                customIdentifier: identifier,
                history: identifier.flatMap({ self.taskHistoriesByCustomIdentifier[$0] })
            )
        }
        
        let tombstoned: [Element] = tomstonedCustomIdentifiers.map {
            return Element(
                source: nil,
                customIdentifier: $0,
                history: self.taskHistoriesByCustomIdentifier[$0]
            )
        }
        
        return (active + tombstoned).makeIterator().eraseToAnyIterator()
    }
}
