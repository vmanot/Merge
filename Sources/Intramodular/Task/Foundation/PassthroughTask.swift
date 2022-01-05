//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Swift

/// A mutable task.
open class PassthroughTask<Success, Error: Swift.Error>: TaskBase<Success, Error> {
    public typealias Body = (PassthroughTask) -> AnyCancellable
    
    private let queue = DispatchQueue(label: "com.vmanot.PassthroughTask")
    private let body: Body
    private var bodyCancellable: AnyCancellable = .empty()
    
    public convenience override init() {
        self.init(body: { _ in .empty() })
    }
    
    public required init(body: @escaping Body) {
        self.body = body
        
        super.init()
    }
    
    required convenience public init(action: @escaping () -> Success) {
        self.init { (task: PassthroughTask<Success, Error>) in
            task.start()
            task.succeed(with: action())
            
            return .empty()
        }
    }
    
    required convenience public init(
        _ attemptToFulfill: @escaping (@escaping (Result<Success, Error>) -> ()) -> Void
    ) {
        self.init { (task: PassthroughTask<Success, Error>) in
            attemptToFulfill { [weak task] result in
                switch result {
                    case .success(let value):
                        task?.succeed(with: value)
                    case .failure(let value):
                        task?.fail(with: value)
                }
            }
            
            return .init(EmptyCancellable())
        }
    }
    
    required convenience public init(
        _ attemptToFulfill: @escaping (@escaping (Result<Success, Error>) -> ()) -> AnyCancellable
    ) {
        self.init { (task: PassthroughTask<Success, Error>) in
            return attemptToFulfill { result in
                switch result {
                    case .success(let value):
                        task.succeed(with: value)
                    case .failure(let value):
                        task.fail(with: value)
                }
            }
        }
    }
    
    required convenience public init(publisher: AnySingleOutputPublisher<Success, Error>) {
        self.init { attemptToFulfill in
            publisher.sinkResult(attemptToFulfill)
        }
    }
    
    required convenience public init<P: SingleOutputPublisher>(publisher: P) where P.Output == Success, P.Failure == Error {
        self.init { attemptToFulfill in
            publisher.sinkResult(attemptToFulfill)
        }
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
    final override public func start() {
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
    final override public func cancel() {
        send(status: .canceled)
    }
    
    /// Publishes a failure.
    final public func fail(with error: Error) {
        send(status: .error(error))
    }
}

// MARK: - Conformances -

extension PassthroughTask: ConnectablePublisher {
    public func connect() -> Cancellable {
        start()
        
        return bodyCancellable
    }
}

extension PassthroughTask: Subject {
    /// Sends a value to the subscriber.
    ///
    /// - Parameter value: The value to send.
    public func send(_ output: Output) {
        send(status: .init(output))
    }
    
    /// Sends a completion signal to the subscriber.
    ///
    /// - Parameter failure: The failure to send.
    public func send(_ failure: Failure) {
        send(status: .init(failure))
    }
    
    /// Sends a completion signal to the subscriber.
    ///
    /// - Parameter completion: A `Completion` instance which indicates whether publishing has finished normally or failed with an error.
    public func send(completion: Subscribers.Completion<Failure>) {
        switch completion {
            case .finished:
                break
            case .failure(let failure):
                send(status: .init(failure))
        }
    }
    
    public func send(subscription: Subscription) {
        subscription.request(.unlimited)
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

extension PassthroughTask where Success == Void, Error == Swift.Error {
    final public class func action(_ action: @escaping (PassthroughTask<Success, Error>) throws -> Void) -> Self {
        .init { (task: PassthroughTask<Success, Error>) in
            task.start()
            
            do {
                task.succeed(with: try action(task))
            } catch {
                task.fail(with: error)
            }
            
            return .empty()
        }
    }
    
    final public class func action(_ action: @escaping () -> Void) -> Self {
        .init { (task: PassthroughTask<Success, Error>) in
            task.start()
            task.succeed(with: action())
            
            return .empty()
        }
    }
    
    final public class func action(_ action: @escaping () throws -> Void) -> Self {
        .action({ _ in try action() })
    }
}

// MARK: - Helpers -

extension SingleOutputPublisher {
    public func convertToTask() -> AnyTask<Output, Failure> {
        PassthroughTask(publisher: self)
            .eraseToAnyTask()
    }
    
    @_disfavoredOverload
    public func convertToTask() -> OpaqueTask {
        convertToTask().eraseToOpaqueTask()
    }
}

extension Publisher {
    public func convertToTask() -> AnyTask<Void, Failure> {
        reduceAndMapTo(()).convertToTask()
    }
    
    @_disfavoredOverload
    public func convertToTask() -> OpaqueTask {
        convertToTask().eraseToOpaqueTask()
    }
}
