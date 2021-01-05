//
// Copyright (c) Vatsal Manot
//

import Swift

extension TaskProtocol where Success == Void {
    public func concatenate(with other: Self) -> AnyTask<Void, Error> {
        PassthroughTask<Void, Error> { (task: PassthroughTask) in
            Publishers.Concatenate(prefix: self, suffix: other).sinkResult { result in
                switch result {
                    case .success(let value): do {
                        switch value {
                            case .started:
                                break
                            case .success(let value):
                                task.succeed(with: value)
                        }
                    }
                    
                    case .failure(let failure): do {
                        switch failure {
                            case .error(let error):
                                task.fail(with: error)
                            case .canceled:
                                task.cancel()
                        }
                    }
                }
            }
        }
        .eraseToAnyTask()
    }
    
    public func concatenate(with elements: [Self]) -> AnyTask<Void, Error> {
        PassthroughTask<Void, Error> { (task: PassthroughTask) in
            Publishers.ConcatenateMany([self] + elements).sinkResult { result in
                switch result {
                    case .success(let value): do {
                        switch value {
                            case .started:
                                break
                            case .success(let value):
                                task.succeed(with: value)
                        }
                    }
                    
                    case .failure(let failure): do {
                        switch failure {
                            case .error(let error):
                                task.fail(with: error)
                            case .canceled:
                                task.cancel()
                        }
                    }
                }
            }
        }
        .eraseToAnyTask()
    }
}
