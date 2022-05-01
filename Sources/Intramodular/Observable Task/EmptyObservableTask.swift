//
// Copyright (c) Vatsal Manot
//

import Combine

public final class EmptyObservableTask<Success, Error: Swift.Error>: ObservableTask {
    public var status: TaskStatus<Success, Error> {
        .idle
    }

    public var objectWillChange: AnyPublisher<TaskStatus<Success, Error>, Never>  {
        Empty().eraseToAnyPublisher()
    }

    public let progress = Progress()

    public var statusDescription: StatusDescription {
        .init(status)
    }

    public var statusDescriptionWillChange: AnyPublisher<StatusDescription, Never>{
        .just(.idle)
    }

    public init() {

    }

    public init() where Success == Void, Error == Never {

    }

    public func start() {

    }

    public func pause() throws {

    }

    public func resume() throws {

    }

    public func cancel() {

    }
}
