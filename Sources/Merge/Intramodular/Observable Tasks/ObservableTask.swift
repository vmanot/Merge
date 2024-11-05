//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Foundation
import Swallow

/// An observable task is a token of activity with status-reporting.
public protocol ObservableTask<Success, Error>: Cancellable, Identifiable, ObjectDidChangeObservableObject where ObjectDidChangePublisher.Output == ObservableTaskStatus<Self.Success, Self.Error> {
    associatedtype Success
    associatedtype Error: Swift.Error

    /// The status of this task.
    var status: ObservableTaskStatus<Success, Error> { get }
    
    /// Start the task.
    func start()
        
    /// Cancel the task.
    func cancel()
}

extension ObservableTask {
    public var statusDescription: ObservableTaskStatusDescription {
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
