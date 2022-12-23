//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swallow

/// A task that performs type erasure by wrapping another task.
public final class AnyTask<Success, Error: Swift.Error>: ObservableTask {
    public typealias ID = AnyHashable
    public typealias Status = TaskStatus<Success, Error>
    public typealias ObjectWillChangePublisher = AnyPublisher<Status, Never>
    
    public let base: any ObservableTask
    
    private let getStatusImpl: () -> Status
    private let getObjectWillChangeImpl: () -> AnyPublisher<Status, Never>
    
    public var id: ID {
        base.id.eraseToAnyHashable()
    }
    
    public var status: Status {
        getStatusImpl()
    }
    
    public var progress: Progress {
        base.progress
    }
    
    public var objectWillChange: ObjectWillChangePublisher {
        getObjectWillChangeImpl()
    }
    
    public var cancellables: Cancellables {
        base.cancellables
    }
    
    private init(
        base: any ObservableTask,
        getStatusImpl: @escaping () -> Status,
        getObjectWillChangeImpl: @escaping () -> AnyPublisher<Status, Never>
    ) {
        self.base = base
        self.getStatusImpl = getStatusImpl
        self.getObjectWillChangeImpl = getObjectWillChangeImpl
    }
    
    public func start() {
        base.start()
    }
    
    public func cancel() {
        base.cancel()
    }
}

extension AnyTask {
    public convenience init<T: ObservableTask>(_ base: T) where T.Success == Success, T.Error == Error {
        self.init(
            base: base,
            getStatusImpl: { base.status },
            getObjectWillChangeImpl: { base.objectWillChange.eraseToAnyPublisher() }
        )
    }
}

extension AnyTask where Success == Any, Error == Swift.Error {
    public convenience init(erasing base: any ObservableTask) {
        self.init(
            base: base,
            getStatusImpl: { base._opaque_status },
            getObjectWillChangeImpl: { base._opaque_statusWillChange }
        )
    }
}

extension AnyTask {
    convenience public init(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async -> Success
    ) where Error == Never {
        self.init(PassthroughTask(priority: priority, operation: operation))
    }
    
    convenience public init(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) where Error == Swift.Error {
        self.init(PassthroughTask(priority: priority, operation: operation))
    }
}

// MARK: - API -

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

extension ObservableTask {
    public func eraseToAnyTask() -> AnyTask<Success, Error> {
        .init(self)
    }
}
