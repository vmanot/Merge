//
// Copyright (c) Vatsal Manot
//

import Combine
import Diagnostics
import Dispatch
import Foundation
import Swift

/// A mutable task.
open class PassthroughTask<Success, Error: Swift.Error>: ObservableTask {
    public typealias Body = (PassthroughTask) -> AnyCancellable
    public typealias Status = TaskStatus<Success, Error>
    
    private let lock = NSRecursiveLock()
    
    private let _objectWillChange = _AsyncObjectWillChangePublisher()
    private let _objectDidChange = PassthroughSubject<Status, Never>()
    
    private var body: Body?
    private var isEvaluatingBody: Bool = false
    private var bodyCancellable: Cancellable?
    private var _status: Status = .idle
    
    public var status: Status {
        lock.withCriticalScope {
            _status
        }
    }
    
    public let objectWillChange: AnyPublisher<Void, Never>
    public let objectDidChange: AnyPublisher<Status, Never>
    
    public required init(body: @escaping Body) {
        self.body = body
        
        self.objectWillChange = _objectWillChange.eraseToAnyPublisher()
        self.objectDidChange = _objectDidChange.eraseToAnyPublisher()
    }
    
    public convenience init() {
        self.init(body: { _ in .empty() })
    }
    
    public func send(status: Status) {
        _objectWillChange.withCriticalScope { _objectWillChange in
            self._send(status: status, _objectWillChange: _objectWillChange)
        }
    }
    
    private func _send(
        status: Status,
        _objectWillChange: ObservableObjectPublisher
    ) {
        guard TaskStatusDescription(status) != TaskStatusDescription(_status) else {
            return
        }
        
        if status == .canceled {
            guard _status != .success || _status == .error else {
                return
            }
        }
        
        func _unsafeCommitStatus() {
            _objectWillChange.send()
            self._status = status
            self._objectDidChange.send(status)
        }
                
        let exitEarly = lock.withCriticalScope {
            guard !isEvaluatingBody else {
                isEvaluatingBody = false
            
                _unsafeCommitStatus()
                                                
                return true
            }
            
            return false
        }
        
        guard !exitEarly else {
            return
        }
        
        // Check whether `body` needs to be run.
        if status == .active && bodyCancellable == nil {
            lock.acquireOrBlock()
            
            if let body = self.body {
                self.isEvaluatingBody = true

                _unsafeCommitStatus()
                
                lock.relinquish() // relinquish before running `body`
                
                let cancellable = SingleAssignmentAnyCancellable()
                
                lock.withCriticalScope {
                    Task._offTheMainThread {
                        await withTaskCancellationHandler {
                            withTaskDependencies(from: self) {
                                cancellable.set(body(self as! Self))
                            }
                        } onCancel: {
                            cancellable.cancel()
                        }
                    }
                    
                    self.bodyCancellable = cancellable
                    self.body = nil
                    
                    /// Body already exited and called .send(status:).
                    guard isEvaluatingBody else {
                        return
                    }
                    
                    isEvaluatingBody = false
                }
            } else {
                lock.relinquish()
                
                assertionFailure()
            }
        } else {
            var cancellable: Cancellable?

            lock.withCriticalScope {
                cancellable = self.bodyCancellable
                
                if status == .canceled {
                    self.bodyCancellable = nil
                }
                
                _unsafeCommitStatus()
            }
                
            if status == .canceled {
                cancellable?.cancel()
            }
        }
    }
    
    /// Start the task.
    final public func start() {
        guard status == .idle else {
            return
        }
        
        send(status: .active)
        
        if Thread.isMainThread {
            assert(status != .idle)
        }
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
        let dependencies = TaskDependencies.current
        
        self.init(publisher: Deferred {
            Future.async(priority: priority, execute: {
                await withTaskDependencies {
                    $0.mergeInPlace(with: dependencies)
                } operation: {
                    await operation()
                }
            })
        })
    }
    
    required convenience public init(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) where Error == Swift.Error {
        let dependencies = TaskDependencies.current

        self.init(publisher: Deferred {
            Future.async(priority: priority, execute: {
                try await withTaskDependencies {
                    $0.mergeInPlace(with: dependencies)
                } operation: {
                    try await operation()
                }
            })
        })
    }
}

// MARK: - API

extension PassthroughTask where Success == Void {
    final public class func action(
        @_implicitSelfCapture _ action: @escaping (PassthroughTask<Success, Error>) -> Void
    ) -> Self {
        .init { (task: PassthroughTask<Success, Error>) in
            task.start()
            task.succeed(with: action(task))
            
            return .empty()
        }
    }
    
    final public class func action(
        priority: TaskPriority? = nil,
        @_implicitSelfCapture _ action: @MainActor @escaping () -> Void
    ) -> Self {
        .action { _ in
            Task(priority: priority) { @MainActor in
                action()
            }
        }
    }
    
    final public class func action(
        priority: TaskPriority? = nil,
        @_implicitSelfCapture _ action: @MainActor @escaping () async throws -> Void
    ) -> Self where Error == Swift.Error {
        Self(priority: priority) { () -> Void in
            try await _runtimeIssueOnError {
                try await action()
            }
        }
    }
}

// MARK: - Helpers

extension Publisher {
    public func convertToTask() -> AnyTask<Void, Failure> {
        reduceAndMapTo(())
            .convertToTask()
    }
    
    @_disfavoredOverload
    public func convertToTask() -> OpaqueObservableTask {
        convertToTask()
            .eraseToOpaqueObservableTask()
    }
    
    public func convertToTask() -> AnyTask<Output, Failure> where Self: SingleOutputPublisher {
        PassthroughTask(publisher: self)
            .eraseToAnyTask()
    }
    
    @_disfavoredOverload
    public func convertToTask() -> AnyTask<Output, Swift.Error> where Self: SingleOutputPublisher {
        PassthroughTask(publisher: mapError({ $0 as (any Swift.Error) }))
            .eraseToAnyTask()
    }
    
    @_disfavoredOverload
    public func convertToTask() -> OpaqueObservableTask where Self: SingleOutputPublisher {
        convertToTask()
            .eraseToOpaqueObservableTask()
    }
}

extension Task {
    /// Convert this `Task` into an observable task.
    public func convertToObservableTask(
        priority: TaskPriority? = nil
    ) -> AnyTask<Success, Failure> {
        publisher(priority: priority).convertToTask()
    }
    
    /// Convert this `Task` into an observable task.
    public func convertToObservableTask<T, U>(
        priority: TaskPriority? = nil
    ) -> AnyTask<T, U> where Success == Result<T, U>, Failure == Never  {
        publisher(priority: priority).flatMap({ $0.publisher }).convertToTask()
    }
}
