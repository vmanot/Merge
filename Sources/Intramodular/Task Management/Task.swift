//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

/// A type-erased shadow protocol for `Task`.
public protocol _opaque_Task: _opaque_Identifiable, CancellablesHolder, Subscription {
    typealias StatusDescription = TaskStatusDescription
    
    var _opaque_status: TaskStatus<Any, Swift.Error> { get }
    var _opaque_statusWillChange: AnyPublisher<TaskStatus<Any, Swift.Error>, Never> { get }
    
    var name: TaskName { get }
    
    var statusDescription: StatusDescription { get }
    var statusDescriptionWillChange: AnyPublisher<StatusDescription, Never> { get }
    
    func start()
}

/// A task is a token of activity with status-reporting.
public protocol TaskProtocol: _opaque_Task, Identifiable, ObservableObject, Publisher where
    ObjectWillChangePublisher.Output == TaskStatus<Self.Success, Self.Error>,
    Self.Output == TaskOutput<Self.Success, Self.Error>,
    Self.Failure == TaskFailure<Self.Error>
{
    associatedtype Success
    associatedtype Error: Swift.Error
    
    associatedtype Output = TaskOutput<Success, Error>
    associatedtype Failure = TaskFailure<Error>
    
    var name: TaskName { get }
    var status: TaskStatus<Success, Error> { get }
    
    func start()
}

// MARK: - Implementation -

extension _opaque_Task where Self: TaskProtocol {
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
}

extension Publisher where Self: TaskProtocol {
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
            .filter({ !$0.isIdle })
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
                    fatalError()
                }
            })
            .receive(subscriber: subscriber)
    }
}

extension Subscription where Self: TaskProtocol {
    public func request(_ demand: Subscribers.Demand) {
        guard demand != .none, statusDescription == .idle else {
            return
        }
        
        start()
    }
}

// MARK: - API -

extension _opaque_Task {
    public func onOutput(perform action: @escaping () -> ()) {
        statusDescriptionWillChange.sink { status in
            if status.isOutput {
                action()
            }
        }
        .store(in: cancellables)
    }
    
    public func onSuccess(perform action: @escaping () -> ()) {
        statusDescriptionWillChange.sink { status in
            if status == .success {
                action()
            }
        }
        .store(in: cancellables)
    }
    
    public func onFailure(perform action: @escaping () -> ()) {
        statusDescriptionWillChange.sink { status in
            if status.isFailure {
                action()
            }
        }
        .store(in: cancellables)
    }
}

extension TaskProtocol {
    public var result: TaskResult<Success, Error>? {
        TaskResult(status)
    }
    
    public var successPublisher: AnyPublisher<Success, Failure> {
        self.compactMap({ TaskStatus<Success, Error>($0).successValue })
            .mapError({ TaskStatus<Success, Error>($0).failure! })
            .eraseToAnyPublisher()
    }
    
    public func onResult(_ receiveCompletion: @escaping (TaskResult<Success, Error>) -> Void) {
        if let result = result {
            receiveCompletion(result)
        } else {
            objectWillChange
                .compactMap(TaskResult.init)
                .sink(receiveValue: receiveCompletion)
                .store(in: cancellables)
        }
    }
    
    public func onStatusChange(receiveValue: @escaping (TaskStatus<Success, Error>) -> ()) {
        objectWillChange.sink(receiveValue: receiveValue)
            .store(in: cancellables)
    }
    
    public func onStatus(
        _ status: StatusDescription,
        perform action: @escaping (TaskStatus<Success, Error>) -> ()
    ) {
        objectWillChange
            .filter({ status == TaskStatusDescription($0) })
            .sink(receiveValue: action)
            .store(in: cancellables)
    }
}

