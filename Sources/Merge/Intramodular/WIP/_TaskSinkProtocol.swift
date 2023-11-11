//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

@_spi(Internal)
public protocol _TaskSinkProtocol<_TaskFailureType> {
    associatedtype _TaskFailureType: Error
    associatedtype _ResultFailureType: Error
    
    func receive<Success: Sendable>(
        _ task: Task<Success, _TaskFailureType>
    ) async -> Result<Success, _ResultFailureType>
}

@_spi(Internal)
extension _TaskSinkProtocol {
    @discardableResult
    func _opaque_receive<Success: Sendable>(
        _ task: Task<Success, Never>
    ) async -> Result<Success, Error> where _TaskFailureType == Never {
        await self.receive(task).mapError({ $0 as Error })
    }
    
    @discardableResult
    func _opaque_receive<Success: Sendable>(
        _ task: Task<Success, Error>
    ) async -> Result<Success, Error> where _TaskFailureType == Swift.Error {
        await self.receive(task).mapError({ $0 as Error })
    }
}

// MARK: - Implemented Conformances

@_spi(Internal)
extension TaskQueue: _TaskSinkProtocol {
    public typealias _TaskFailureType = Never
    public typealias _ResultFailureType = CancellationError
    
    public func receive<Success: Sendable>(
        _ task: Task<Success, Never>
    ) async -> Result<Success, _ResultFailureType> {
        await _performCancellable {
            await task.value
        }
    }
}

@_spi(Internal)
extension ThrowingTaskQueue: _TaskSinkProtocol {
    public typealias _TaskFailureType = Swift.Error
    public typealias _ResultFailureType = Swift.Error
    
    public func receive<Success: Sendable>(
        _ task: Task<Success, Swift.Error>
    ) async -> Result<Success, _ResultFailureType> {
        let result = await _performCancellable {
            await Result(catching: { () -> Success in
                try await task.value
            })
        }
        
        switch result {
            case .success(let result):
                return result
            case .failure(let error):
                return .failure(error)
        }
    }
}
