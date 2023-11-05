//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Foundation
import Swallow

/// An observable task is a token of activity with status-reporting.
public protocol ObservableTask<Success, Error>: Cancellable, Identifiable, _ObservableObjectX where ObjectDidChangePublisher.Output == TaskStatus<Self.Success, Self.Error> {
    associatedtype Success
    associatedtype Error: Swift.Error

    /// The status of this task.
    var status: TaskStatus<Success, Error> { get }
    
    /// Start the task.
    func start()
        
    /// Cancel the task.
    func cancel()
}

extension ObservableTask {
    public var statusDescription: TaskStatusDescription {
        .init(status)
    }
}

// MARK: - Implementation

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
    public func blockAndUnwrap(on queue: DispatchQueue? = nil) throws -> Success {
        try successPublisher.subscribeAndWaitUntilDone(on: queue).unwrap().get()
    }
}
