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
    ) -> Publishers.FlatMap<Future<T, Never>, Self> {
        let queue = TaskQueue()
        
        return flatMapAsync { value in
            await queue.perform(operation: { await transform(value) })
        }
    }
    
    public func flatMapAsyncSequential<T>(
        _ transform: @escaping (Output) async throws -> T
    ) -> Publishers.FlatMap<Future<T, Error>, Publishers.MapError<Self, Error>> {
        let queue = ThrowingTaskQueue()
        
        return flatMapAsync { value in
            try await queue.perform(operation: { try await transform(value) })
        }
    }
}
