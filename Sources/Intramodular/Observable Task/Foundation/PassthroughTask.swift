//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift

/// A mutable task.
open class PassthroughTask<Success, Error: Swift.Error>: ObservableTask {
    public typealias Body = (PassthroughTask) -> AnyCancellable
    public typealias Status = TaskStatus<Success, Error>
    
    private let queue = DispatchQueue(label: "com.vmanot.PassthroughTask")
    private let body: Body
    private var bodyCancellable: AnyCancellable = .empty()
    
    private let statusValueSubject = CurrentValueSubject<Status, Never>(.idle)
    
    public var status: Status {
        statusValueSubject.value
    }
    
    public let objectWillChange: AnyPublisher<Status, Never>
    
    public let progress = Progress()
    
    public required init(body: @escaping Body) {
        self.body = body
        self.objectWillChange = statusValueSubject
            .receive(on: MainThreadScheduler.shared)
            .eraseToAnyPublisher()
    }
    
    public convenience init() {
        self.init(body: { _ in .empty() })
    }
    
    open func didSend(status: Status) {
        
    }
    
    public func send(status: Status) {
        queue.sync {
            defer {
                didSend(status: status)
            }
            
            switch status {
                case .idle:
                    assertionFailure()
                case .active:
                    statusValueSubject.send(.active)
                case .paused:
                    statusValueSubject.send(.paused)
                case .canceled: do {
                    statusValueSubject.send(.canceled)
                    bodyCancellable.cancel()
                    cancellables.cancel()
                }
                case .success(let success): do {
                    statusValueSubject.send(.success(success))
                }
                case .error(let error): do {
                    statusValueSubject.send(.error(error))
                }
            }
        }
    }
    
    /// Start the task.
    final public func start() {
        func _start() {
            send(status: .active)
            
            bodyCancellable = body(self as! Self)
        }
        
        guard statusDescription == .idle else {
            return
        }
        
        _start()
    }
    
    /// Publishes a success.
    final public func succeed(with value: Success) {
        send(status: .success(value))
    }
    
    /// Cancel the task.
    final public func cancel() {
        send(status: .canceled)
    }
    
    /// Publishes a failure.
    final public func fail(with error: Error) {
        send(status: .error(error))
    }
    
    // MARK: Initializers
    
    required convenience public init(action: @escaping () -> Success) {
        self.init { (task: PassthroughTask<Success, Error>) in
            task.start()
            task.succeed(with: action())
            
            return .empty()
        }
    }
    
    required convenience public init(
        _ attemptToFulfill: @escaping (@escaping (Result<Success, Error>) -> Void) -> AnyCancellable
    ) {
        self.init { (task: PassthroughTask<Success, Error>) -> AnyCancellable in
            var capturedTask: PassthroughTask? = task

            return attemptToFulfill { result in
                assert(capturedTask != nil)

                switch result {
                    case .success(let value):
                        capturedTask?.succeed(with: value)
                    case .failure(let value):
                        capturedTask?.fail(with: value)
                }
                
                capturedTask = nil
            }
        }
    }
    
    required convenience public init(
        _ attemptToFulfill: @escaping (@escaping (Result<Success, Error>) -> Void) -> Void
    ) {
        self.init { (task: PassthroughTask<Success, Error>) -> AnyCancellable in
            var capturedTask: PassthroughTask? = task
            
            attemptToFulfill { result in
                assert(capturedTask != nil)
                
                switch result {
                    case .success(let value):
                        capturedTask?.succeed(with: value)
                    case .failure(let value):
                        capturedTask?.fail(with: value)
                }
                
                capturedTask = nil
            }
            
            return .init(EmptyCancellable())
        }
    }
    
    required convenience public init(publisher: AnySingleOutputPublisher<Success, Error>) {
        self.init { attemptToFulfill -> AnyCancellable in
            publisher.sinkResult(attemptToFulfill)
        }
    }
    
    required convenience public init<P: SingleOutputPublisher>(
        publisher: P
    ) where P.Output == Success, P.Failure == Error {
        self.init(publisher: AnySingleOutputPublisher(publisher))
    }
    
    required convenience public init(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async -> Success
    ) where Error == Never {
        self.init(publisher: Future.async(priority: priority, execute: operation))
    }
    
    required convenience public init(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) where Error == Swift.Error {
        self.init(publisher: Future.async(priority: priority, execute: operation))
    }
}

// MARK: - API -

extension PassthroughTask where Success == Void {
    final public class func action(_ action: @escaping (PassthroughTask<Success, Error>) -> Void) -> Self {
        .init { (task: PassthroughTask<Success, Error>) in
            task.start()
            task.succeed(with: action(task))
            
            return .empty()
        }
    }
    
    final public class func action(_ action: @escaping () -> Void) -> Self {
        .action({ _ in action() })
    }
}

// MARK: - Helpers -

extension SingleOutputPublisher {
    public func convertToTask() -> AnyTask<Output, Failure> {
        PassthroughTask(publisher: self)
            .eraseToAnyTask()
    }
    
    @_disfavoredOverload
    public func convertToTask() -> OpaqueObservableTask {
        convertToTask().eraseToOpaqueObservableTask()
    }
}

extension Publisher {
    public func convertToTask() -> AnyTask<Void, Failure> {
        reduceAndMapTo(()).convertToTask()
    }
    
    @_disfavoredOverload
    public func convertToTask() -> OpaqueObservableTask {
        convertToTask().eraseToOpaqueObservableTask()
    }
}

extension Task {
    /// Convert this `Task` into an observable task.
    public func convertToObservableTask(
        priority: TaskPriority? = nil
    ) -> AnyTask<Success, Failure> {
        publisher(priority: priority).convertToTask()
    }
}

extension Task {
    /// Convert this `Task` into an observable task.
    public func convertToObservableTask<T, U>(
        priority: TaskPriority? = nil
    ) -> AnyTask<T, U> where Success == Result<T, U>, Failure == Never  {
        publisher(priority: priority).flatMap({ $0.publisher }).convertToTask()
    }
}
