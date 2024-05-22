//
// Copyright (c) Vatsal Manot
//

import Combine

extension Publisher {
    public func flatMapAsync<T>(
        _ transform: @escaping (Output) async -> T
    ) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    let result = await transform(value)
                    promise(.success(result))
                }
            }
        }
    }
    
    public func flatMapAsync<T>(
        _ transform: @escaping (Output) async throws -> T
    ) -> Publishers.FlatMap<Future<T, any Swift.Error>, Publishers.MapError<Self, any Swift.Error>> {
        mapError({ $0 as Error}).flatMap { value in
            Future { promise in
                Task {
                    do {
                        let result = try await transform(value)
                        
                        promise(.success(result))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
    
    public func flatMapAsyncSequential<T>(
        _ transform: @escaping (Output) async -> T
    ) -> Publishers.FlatMap<Future<T, any Error>, Publishers.SetFailureType<Self, any Error>> {
        let queue = TaskQueue()
        
        let x = flatMap { value in
            Future<T, Error> { fulfill in
                queue.addTask {
                    let result = await Result(catching: {
                        await transform(value)
                    })
                    
                    fulfill(result)
                }
            }
        }
        
        return x
    }
    
    public func flatMapAsyncSequential<T>(
        _ transform: @escaping (Output) async throws -> T
    ) -> Publishers.FlatMap<Publishers.MapError<Future<T, any Error>, any Error>, Publishers.MapError<Self, any Error>> {
        let queue = ThrowingTaskQueue()
        
        let x = flatMap { value in
            Future<T, Error> { fulfill in
                queue.addTask {
                    let result = await Result(catching: {
                        try await transform(value)
                    })
                    
                    fulfill(result)
                }
            }
        }
        
        return x
    }
}
