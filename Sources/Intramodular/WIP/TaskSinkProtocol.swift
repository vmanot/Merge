//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

public protocol TaskSinkProtocol<_TaskFailureType> {
    associatedtype _TaskFailureType: Error
    associatedtype _ResultFailureType: Error
    
    func receive<Success: Sendable>(
        _ task: Task<Success, _TaskFailureType>
    ) async -> Result<Success, _ResultFailureType>
}

extension TaskSinkProtocol where _TaskFailureType == Never {
    func _opaque_receive<Success: Sendable>(
        _ task: Task<Success, Never>
    ) async -> Result<Success, Error> {
        await self.receive(task).mapError({ $0 as Error })
    }
}

// MARK: - Implemented Conformances

extension TaskQueue: TaskSinkProtocol {
    public typealias _TaskFailureType = Never
    public typealias _ResultFailureType = CancellationError
    
    public func receive<Success: Sendable>(
        _ task: Task<Success, Never>
    ) async -> Result<Success, _ResultFailureType> {
        await perform {
            await task.value
        }
    }
}

@propertyWrapper
public final class TaskSunk<Success, Failure: Error> {
    private let sink: any TaskSinkProtocol<Failure>
    
    public var _outputPublisher = PassthroughSubject<Result<Success, Error>, Never>()
    
    @MutexProtected
    public var output: Result<Success, Error>? = nil
    
    public var wrappedValue: Success? {
        try? output?.get()
    }
    
    public init(
        queueWithPolicy queuePolicy: TaskQueue.Policy
    ) where Failure == Never {
        self.sink = TaskQueue(policy: queuePolicy)
    }
    
    public var projectedValue: TaskSunk {
        self
    }
    
    fileprivate func publish(_ output: Result<Success, Error>) {
        self.$output.withCriticalRegion {
            $0 = output
            
            _outputPublisher.send(output)
        }
    }
}

extension TaskSunk where Failure == Never {
    public var publisher: AnyPublisher<Success, Never> {
        _outputPublisher.tryMap({ try $0.get() }).discardError().eraseToAnyPublisher()
    }
    
    public func callAsFunction(
        _ operation: @Sendable @escaping () async -> Success
    ) where Failure == Never {
        Task {
            let result = await sink._opaque_receive(Task {
                await operation()
            })
            
            self.publish(result)
        }
    }
    
    public func callAsFunction(
        _ operation: @Sendable @escaping () async -> AsyncStream<Success>
    ) where Failure == Never {
        Task {
            await sink._opaque_receive(Task {
                let stream = await operation()
                
                do {
                    for try await value in stream.eraseToAnyAsyncSequence() {
                        self.publish(.success(value))
                    }
                } catch {
                    self.publish(.failure(error))
                }
            })
        }
    }
}
