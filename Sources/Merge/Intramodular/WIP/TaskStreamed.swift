//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

/// A property wrapper that represents a property that is the latest output in a stream of tasks.
@propertyWrapper
public final class TaskStreamed<Success, Failure: Error> {
    public typealias Value = Success?
    
    private let objectWillChangeRelay = ObjectWillChangePublisherRelay()
    private let sink: any _TaskSinkProtocol<Failure>
    
    public var _outputPublisher = PassthroughSubject<Result<Success, Error>, Never>()
    
    @MainActor
    @Published
    public private(set) var latest: AnyTask<Success, Failure>?
    
    @MutexProtected
    public var output: Result<Success, Error>? = nil
    
    public var wrappedValue: Success? {
        try? output?.get()
    }
    
    public init(
        wrappedValue: Success? = nil
    ) where Failure == Never {
        self.sink = TaskQueue()
    }
    
    public init(
        wrappedValue: Success? = nil,
        failureType: Failure.Type = Failure.self
    ) where Failure == Swift.Error {
        self.sink = ThrowingTaskQueue()
    }
    
    public var projectedValue: TaskStreamed {
        self
    }
    
    @MainActor
    public static subscript<EnclosingSelf>(
        _enclosingInstance enclosingInstance: EnclosingSelf,
        wrapped wrappedKeyPath: KeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: KeyPath<EnclosingSelf, TaskStreamed>
    ) -> Value {
        get {
            let propertyWrapper = enclosingInstance[keyPath: storageKeyPath]
            
            propertyWrapper.objectWillChangeRelay.destination = enclosingInstance
            
            return propertyWrapper.wrappedValue
        }
    }
    
    fileprivate func publish(_ output: Result<Success, Error>) {
        self.$output.withCriticalRegion {
            $0 = output
            
            _outputPublisher.send(output)
        }
    }
}

extension TaskStreamed where Failure == Never {
    public var publisher: AnyPublisher<Success, Never> {
        _outputPublisher.tryMap({ try $0.get() }).discardError().eraseToAnyPublisher()
    }
}

extension TaskStreamed {
    public func callAsFunction(
        @_implicitSelfCapture _ operation: @Sendable @escaping () async -> Success
    ) where Failure == Never {
        let task = AnyTask {
            await operation()
        }
        
        Task {
            await MainActor.run {
                self.objectWillChangeRelay.source = task
                self.latest = task
                
                assert(task.status == .idle)
            }
            
            let result: Result<Success?, Error> = await self.sink._opaque_receive(Task {
                #try(.optimistic) {
                    try await task.value
                }
            })
            
            switch result {
                case .success(let success):
                    if let success {
                        self.publish(.success(success))
                    } else {
                        assertionFailure()
                    }
                case .failure(let error):
                    self.publish(.failure(error))
            }
        }
    }
    
    public func callAsFunction(
        @_implicitSelfCapture _ operation: @Sendable @escaping () async throws -> Success
    ) where Failure == Swift.Error {
        let task = AnyTask {
            try await operation()
        }
        
        Task {
            await MainActor.run {
                self.objectWillChangeRelay.source = task
                self.latest = task
                
                assert(task.status == .idle)
            }
            
            let result: Result<Success, Error> = await sink._opaque_receive(Task {
                try await _warnOnThrow {
                    try await task.value
                }
            })
            
            self.publish(result)
        }
    }
    
    @_disfavoredOverload
    public func callAsFunction(
        @_implicitSelfCapture _ operation: @Sendable @escaping () async -> AsyncStream<Success>
    ) where Failure == Never {
        let task = AnyTask { () -> Success in
            let stream = await operation()
            
            var last: Success?
            
            do {
                for try await value in stream.eraseToAnyAsyncSequence() {
                    last = value
                    
                    self.publish(.success(value))
                }
            } catch {
                self.publish(.failure(error))
            }
            
            return last!
        }
        
        Task {
            await MainActor.run {
                self.objectWillChangeRelay.source = task
                self.latest = task
                
                assert(task.status == .idle)
            }
            
            await sink._opaque_receive(Task {
                #try(.optimistic) {
                    try await task.value
                }
            })
        }
    }
    
    public func stream(
        @_implicitSelfCapture _ operation: @Sendable @escaping () async -> Success
    ) where Failure == Never {
        callAsFunction(operation)
    }
    
    public func stream(
        @_implicitSelfCapture _ operation: @Sendable @escaping () async throws -> Success
    ) where Failure == Swift.Error {
        callAsFunction(operation)
    }
}
