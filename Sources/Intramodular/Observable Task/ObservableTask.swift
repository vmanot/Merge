//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

/// A task is a token of activity with status-reporting.
public protocol ObservableTask: _opaque_ObservableTask, Identifiable, ObservableObject, Publisher where
    ObjectWillChangePublisher.Output == TaskStatus<Self.Success, Self.Error>,
    Self.Output == TaskOutput<Self.Success, Self.Error>,
    Self.Failure == TaskFailure<Self.Error>
{
    associatedtype Success
    associatedtype Error: Swift.Error
    
    associatedtype Output = TaskOutput<Success, Error>
    associatedtype Failure = TaskFailure<Error>
    
    var taskIdentifier: TaskIdentifier { get }
    var status: TaskStatus<Success, Error> { get }
    var progress: Progress { get }
    
    func start()
    func pause() throws
    func resume() throws
    func cancel()
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

extension Publisher where Self: ObservableTask {
    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Output, S.Failure == Failure {
        guard !status.isTerminal else {
            if let output = status.output {
                return Just(output)
                    .setFailureType(to: Failure.self)
                    .receive(subscriber: subscriber)
            } else if let failure = status.failure {
                return Fail<Output, Failure>(error: failure)
                    .receive(subscriber: subscriber)
            } else {
                return assertionFailure()
            }
        }
        
        start()
        
        objectWillChange
            .filter({ $0 != .idle })
            .setFailureType(to: Failure.self)
            .flatMap({ status -> AnyPublisher<Output, Failure> in
                if let output = status.output {
                    return Just(output)
                        .setFailureType(to: Failure.self)
                        .eraseToAnyPublisher()
                } else if let failure = status.failure {
                    return Fail<Output, Failure>(error: failure)
                        .eraseToAnyPublisher()
                } else {
                    assertionFailure()
                    
                    return Fail<Output, Failure>(error: .canceled)
                        .eraseToAnyPublisher()
                }
            })
            .receive(subscriber: subscriber)
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

// MARK: - API -

extension ObservableTask {
    public func startIfNecessary() {
        guard status == .idle else {
            return
        }
        
        start()
    }
    
    @discardableResult
    public func startAndStore(in cancellables: Cancellables) -> Self {
        start()
        
        store(in: cancellables)
        
        return self
    }
}

extension ObservableTask {
    @discardableResult
    public func blockAndUnwrap() throws -> Success {
        try successPublisher.subscribeAndWaitUntilDone().get()
    }
}