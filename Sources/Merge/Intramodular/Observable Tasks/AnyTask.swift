//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

/// A task that performs type erasure by wrapping another task.
public final class AnyTask<Success, Error: Swift.Error>: ObservableObject, ObservableTask, @unchecked Sendable {
    public typealias ID = AnyHashable
    public typealias Status = ObservableTaskStatus<Success, Error>
    
    public let base: any ObservableTask<Success, Error>
    public let objectDidChange: AnyPublisher<Status, Never>
    
    public var id: ID {
        base.id.eraseToAnyHashable()
    }
    
    public var status: Status {
        base.status
    }
    
    public var objectWillChange: AnyObjectWillChangePublisher {
        .init(from: base)
    }
    
    private init<T: ObservableTask<Success, Error>>(
        _erasing base: T
    ) {
        if let base = base as? AnyTask<Success, Error> {
            self.base = base.base
        } else {
            self.base = base
        }
        
        self.objectDidChange = base.objectDidChange.eraseToAnyPublisher()
    }
    
    public func start() {
        base.start()
    }
    
    public func cancel() {
        base.cancel()
    }
}

// MARK: - Initializers

extension AnyTask {
    public convenience init<T: ObservableTask>(
        erasing base: T
    ) where T.Success == Success, T.Error == Error {
        self.init(_erasing: base)
    }
    
    public convenience init(
        erasing base: any ObservableTask<Success, Error>
    ) {
        self.init(_erasing: base)
    }
    
    public convenience init(
        erasing base: OpaqueObservableTask
    ) where Success == Any, Error == Swift.Error {
        self.init(_erasing: base)
    }
    
    convenience public init(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async -> Success
    ) where Error == Never {
        self.init(erasing: PassthroughTask(priority: priority, operation: operation))
    }
    
    convenience public init(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) where Error == Swift.Error {
        self.init(erasing: PassthroughTask(priority: priority, operation: operation))
    }
}

extension AnyTask {
    public static func failure(_ error: Error) -> AnyTask {
        Fail<Success, Error>(error: error)
            .convertToTask()
    }
    
    public static func failure(description: String) -> AnyTask where Error == Swift.Error {
        Fail<Success, Error>(error: CustomStringError(description: description))
            .convertToTask()
    }
    
    public static func success(_ success: Success) -> AnyTask {
        Just(success)
            .setFailureType(to: Error.self)
            .convertToTask()
    }
    
    public static func just(_ result: Result<Success, Error>) -> AnyTask {
        switch result {
            case .failure(let error):
                return .failure(error)
            case .success(let success):
                return .success(success)
        }
    }
}

// MARK: - Conformances

extension AnyTask: Equatable {
    public static func == (lhs: AnyTask, rhs: AnyTask) -> Bool {
        lhs.base.eraseToOpaqueObservableTask() == rhs.base.eraseToOpaqueObservableTask()
    }
    
    public static func == (lhs: AnyTask, rhs: OpaqueObservableTask) -> Bool {
        lhs.base.eraseToOpaqueObservableTask() == rhs
    }
}

// MARK: - API

extension ObservableTask {
    public func eraseToAnyTask() -> AnyTask<Success, Error> {
        .init(erasing: self)
    }
    
    public func _opaque_eraseToAnyTask() -> any ObservableTask {
        eraseToAnyTask()
    }
}

extension Task {
    /// Returns a type-erased version of self.
    public func eraseToAnyTask() -> AnyTask<Success, Error> {
        .init(erasing: PassthroughTask {
            try await value
        })
    }
}
