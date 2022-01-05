//
// Copyright (c) Vatsal Manot
//

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
