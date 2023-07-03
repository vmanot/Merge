//
// Copyright (c) Vatsal Manot
//

import Swift

extension ObservableTask where Success == Void, Error == Swift.Error {
    public func concatenate(
        with other: Self
    ) -> AnyTask<Void, Error> {
        PassthroughTask<Void, Error> { (task: PassthroughTask) in
            Publishers.Concatenate(prefix: self.successPublisher, suffix: other.successPublisher)
                .reduceAndMapTo(())
                .sinkResult { result in
                    switch result {
                        case .success(let value):
                            task.succeed(with: value)
                        case .failure(let error):
                            task.fail(with: error)
                    }
                }
        }
        .eraseToAnyTask()
    }
    
    public func concatenate(with elements: [Self]) -> AnyTask<Void, Error> {
        PassthroughTask<Void, Error> { (task: PassthroughTask) in
            Publishers.ConcatenateMany([self.successPublisher] + elements.map({ $0.successPublisher }))
                .reduceAndMapTo(())
                .sinkResult { result in
                    switch result {
                        case .success(let value):
                            task.succeed(with: value)
                        case .failure(let error):
                            task.fail(with: error)
                    }
                }
        }
        .eraseToAnyTask()
    }
}
