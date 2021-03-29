//
// Copyright (c) Vatsal Manot
//

import Swallow

/// A type-erased shadow protocol for `Task`.
public protocol _opaque_Task: _opaque_Identifiable, CancellablesHolder, Subscription {
    typealias StatusDescription = TaskStatusDescription
    
    var _opaque_status: TaskStatus<Any, Swift.Error> { get }
    var _opaque_statusWillChange: AnyPublisher<TaskStatus<Any, Swift.Error>, Never> { get }
    
    var taskIdentifier: TaskIdentifier { get }
    var progress: Progress { get }
    
    var statusDescription: StatusDescription { get }
    var statusDescriptionWillChange: AnyPublisher<StatusDescription, Never> { get }
    
    func start()
    func pause() throws
    func resume() throws
    func cancel()
}

public final class OpaqueTask: CustomStringConvertible, Task {
    public typealias Success = Any
    public typealias Error = Swift.Error
    
    private let base: _opaque_Task
    
    public var description: String {
        (base as? CustomStringConvertible)?.description ?? "(Task)"
    }
    
    public var status: TaskStatus<Success, Error> {
        base._opaque_status
    }
    
    public var objectWillChange: AnyPublisher<TaskStatus<Success, Error>, Never>  {
        base._opaque_statusWillChange
    }
    
    public var id: some Hashable {
        base._opaque_id
    }
    
    public var taskIdentifier: TaskIdentifier {
        base.taskIdentifier
    }
    
    public var progress: Progress {
        base.progress
    }
    
    public var statusDescription: StatusDescription {
        base.statusDescription
    }
    
    public var statusDescriptionWillChange: AnyPublisher<StatusDescription, Never>{
        base.statusDescriptionWillChange
    }
    
    public init<T: Task>(_ base: T) {
        self.base = base
    }
    
    public func start() {
        base.start()
    }
    
    public func pause() throws {
        try base.pause()
    }
    
    public func resume() throws {
        try base.resume()
    }
    
    public func cancel() {
        base.cancel()
    }
}

extension Task {
    public func eraseToOpaqueTask() -> OpaqueTask {
        .init(self)
    }
}
