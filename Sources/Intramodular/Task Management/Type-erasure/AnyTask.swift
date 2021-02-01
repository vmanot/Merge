//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swift

/// A task that performs type erasure by wrapping another task.
open class AnyTask<Success, Error: Swift.Error>: Task {
    public typealias Output = TaskOutput<Success, Error>
    public typealias Failure = TaskFailure<Error>
    public typealias Status = TaskStatus<Success, Error>
    
    public let base: _opaque_Task
    
    private let getStatusImpl: () -> Status
    private let getObjectWillChangeImpl: () -> AnyPublisher<Status, Never>
    
    public var id: AnyHashable {
        base._opaque_id
    }
    
    public var status: Status {
        getStatusImpl()
    }
    
    public var progress: Progress {
        base.progress
    }
    
    public var objectWillChange: AnyPublisher<Status, Never> {
        getObjectWillChangeImpl()
    }
    
    public var cancellables: Cancellables {
        base.cancellables
    }
    
    public var name: TaskName {
        base.name
    }
    
    private init(
        base: _opaque_Task,
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
    public convenience init<T: Task>(_ base: T) where T.Success == Success, T.Error == Error {
        self.init(
            base: base,
            getStatusImpl: { base.status },
            getObjectWillChangeImpl: { base.objectWillChange.eraseToAnyPublisher() }
        )
    }
}

extension AnyTask where Success == Any, Error == Swift.Error {
    public convenience init(_opaque base: _opaque_Task) {
        self.init(
            base: base,
            getStatusImpl: { base._opaque_status },
            getObjectWillChangeImpl: { base._opaque_statusWillChange }
        )
    }
}

// MARK: - API -

extension AnyTask {
    public static func failure(_ error: Error) -> AnyTask {
        AnyPublisher<Success, Error>
            .failure(error)
            .convertToTask()
    }
    
    public static func success(_ success: Success) -> AnyTask {
        AnyPublisher<Success, Error>
            .just(success)
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

extension Task {
    public func eraseToAnyTask() -> AnyTask<Success, Error> {
        .init(self)
    }
}
