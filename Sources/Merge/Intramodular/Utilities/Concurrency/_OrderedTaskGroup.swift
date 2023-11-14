//
// Copyright (c) Vatsal Manot
//

import FoundationX
import Swallow

/// A `TaskGroup` that guarantees that tasks are started in the order they are added.
public struct _OrderedTaskGroup<ChildTaskResult: Sendable> {
    struct Base {
        let addTask: ((priority: TaskPriority?, operation: @Sendable () async -> ChildTaskResult)) -> Void
        let next: () async -> ChildTaskResult?
        let waitForAll: () async -> Void
        let isEmpty: () -> Bool
        let cancelAll: () -> Void
        let isCancelled: () -> Bool
    }
    
    private var base: Base
    
    init(base: Base) {
        self.base = base
    }
    
    public func addTask(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async -> ChildTaskResult
    ) {
        base.addTask((priority: priority, operation))
    }
    
    public func addTaskUnlessCancelled(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async -> ChildTaskResult
    ) -> Bool {
        guard !base.isCancelled() else {
            return false
        }
        
        addTask(priority: priority, operation: operation)
        
        return true
    }
    
    @available(*, unavailable)
    public func next() async -> ChildTaskResult? {
        await base.next()
    }
    
    @available(*, unavailable)
    public func waitForAll() async {
        await base.waitForAll()
    }
    
    @available(*, unavailable)
    public var isEmpty: Bool {
        base.isEmpty()
    }
    
    @available(*, unavailable)
    public func cancelAll() {
        base.cancelAll()
    }
    
    @available(*, unavailable)
    public var isCancelled: Bool {
        base.isCancelled()
    }
}

enum _TaskGroupMethodInvocation<ChildTaskResult> {
    case addTask(priority: TaskPriority?, operation: @Sendable () async -> ChildTaskResult)
    
    func apply(to x: inout TaskGroup<ChildTaskResult>) {
        switch self {
            case let .addTask(priority, operation):
                x.addTask(priority: priority, operation: operation)
        }
    }
}

public func _withOrderedTaskGroup<ChildTaskResult, Result>(
    of childTaskResultType: ChildTaskResult.Type,
    returning returnType: Result.Type = Result.self,
    body: (_OrderedTaskGroup<ChildTaskResult>) -> Result
) async -> Result {
    return await withTaskGroup(of: childTaskResultType, returning: returnType) { group -> Result in
        let _group = group
        let deferred: _LockedState<[(inout TaskGroup<ChildTaskResult>) async -> Void]> = .init(initialState: [])
        
        func addTask(_ params: (priority: TaskPriority?, operation: @Sendable () async -> ChildTaskResult)) {
            deferred.withLock {
                $0.append { (group: inout TaskGroup<ChildTaskResult>) -> Void in
                    await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) in
                        group.addTask {
                            continuation.resume(returning: ())
                            
                            return await params.operation()
                        }
                    }
                }
            }
        }
        
        func next() async -> ChildTaskResult? {
            fatalError(.unsupported)
            
            // await group.next()
        }
        
        func waitForAll() async {
            fatalError(.unsupported)
            // await group.waitForAll()
        }
        
        func isEmpty() -> Bool {
            fatalError(.unsupported)
            
            // pointer.pointee.isEmpty
        }
        
        func cancelAll() {
            _group.cancelAll()
        }
        
        func isCancelled() -> Bool {
            _group.isCancelled
        }
        
        let _orderedGroup = _OrderedTaskGroup(
            base: .init(
                addTask: addTask,
                next: next,
                waitForAll: waitForAll,
                isEmpty: isEmpty,
                cancelAll: cancelAll,
                isCancelled: isCancelled
            )
        )
        
        let result = body(_orderedGroup)
        
        for invocation in deferred.withLock({ $0 }) {
            await invocation(&group)
        }
        
        await group.waitForAll()
        
        return result
    }
}
