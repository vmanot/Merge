//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Swift

extension Task {
    /// The result of this task expressed as a publisher.
    public func publisher(priority: TaskPriority? = nil) -> AnySingleOutputPublisher<Success, Failure> {
        let subject = PassthroughSubject<Success, Failure>()

        let task = Task<Void, Never>.detached(priority: priority) {
            switch await result {
                case _ where Task<Never, Never>.isCancelled:
                    subject.send(completion: .finished)
                case .success(let value):
                    subject.send(value)
                    subject.send(completion: .finished)
                case .failure(let error):
                    subject.send(completion: .failure(error))
            }
        }

        return subject
            .handleEvents(receiveCancel: task.cancel)
            ._unsafe_eraseToAnySingleOutputPublisher()
    }
}

extension Task where Success == Never, Failure == Never {
    public static func sleep(_ duration: DispatchTimeInterval) async throws {
        switch duration {
            case .seconds(let int):
                try await sleep(nanoseconds: UInt64(int) * 1_000_000_000)
            case .milliseconds(let int):
                try await sleep(nanoseconds: UInt64(int) * 1_000_000)
            case .microseconds(let int):
                try await sleep(nanoseconds: UInt64(int) * 1_000)
            case .nanoseconds(let int):
                try await sleep(nanoseconds: UInt64(int))
            case .never:
                break
            @unknown default:
                fatalError()
        }
    }
}

