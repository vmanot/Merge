//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Foundation
import Swallow

/// An observable task is a token of activity with status-reporting.
public protocol ObservableTask: _opaque_ObservableTask, Identifiable, ObservableObject where
    ObjectWillChangePublisher.Output == TaskStatus<Self.Success, Self.Error> {
    associatedtype Success
    associatedtype Error: Swift.Error

    /// The status of this task.
    var status: TaskStatus<Success, Error> { get }
        
    /// The progress of the this task.
    var progress: Progress { get }
    
    /// Start the task.
    func start()
        
    /// Pause the task.
    func pause() throws
        
    /// Resume the task.
    func resume() throws
        
    /// Cancel the task.
    func cancel()
}

extension ObservableTask {
    /// The result from a task, after it completes.
    ///
    /// - returns: The task's result.
    public var result: TaskResult<Success, Error> {
        get async throws {
            RuntimeIssuesLogger.default.log(.default, message: "This code is unreliable")
            
            return try await resultPublisher.output()
        }
    }
    
    /// The successful result of a task, after it completes.
    ///
    /// - returns: The task's successful result.
    /// - throws: An error indicating task failure or task cancellation.
    public var value: Success {
        get async throws {
            try await successPublisher.output()
        }
    }
}

// MARK: - Implementation -

extension _opaque_ObservableTask where Self: ObservableTask {
    public var _opaque_status: TaskStatus<Any, Swift.Error> {
        status.map({ $0 as Any }).mapError({ $0 as Swift.Error })
    }
    
    public var _opaque_statusWillChange: AnyPublisher<TaskStatus<Any, Swift.Error>, Never> {
        objectWillChange
            .map({ $0.map({ $0 as Any }).mapError({ $0 as Swift.Error }) })
            .eraseToAnyPublisher()
    }
    
    public var statusDescription: StatusDescription {
        .init(status)
    }
    
    public var statusDescriptionWillChange: AnyPublisher<StatusDescription, Never> {
        objectWillChange
            .map({ StatusDescription($0) })
            .eraseToAnyPublisher()
    }
    
    public func pause() throws {
        throw Never.Reason.unsupported
    }
    
    public func resume() throws {
        throw Never.Reason.unsupported
    }
}

extension Subscription where Self: ObservableTask {
    public func request(_ demand: Subscribers.Demand) {
        guard demand != .none, statusDescription == .idle else {
            return
        }
        
        start()
    }
}

extension ObservableTask {
    @discardableResult
    public func blockAndUnwrap() throws -> Success {
        try successPublisher.subscribeAndWaitUntilDone().get()
    }
}
