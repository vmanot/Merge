//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Combine
import Swift

extension Future {
    /// Creates a publisher that invokes an asynchronous closure.
    public static func async(
        priority: TaskPriority?,
        execute work: @escaping () async -> Output
    ) -> Future<Output, Failure> where Failure == Never {
        .init { attemptToFulfill in
            Task.detached(priority: priority) {
                await attemptToFulfill(.success(work()))
            }
        }
    }
    
    /// Creates a publisher that invokes an asynchronous closure.
    public static func async(
        priority: TaskPriority? = nil,
        execute work: @escaping () async throws -> Output
    ) -> Future<Output, Failure> where Failure == Error {
        .init { attemptToFulfill in
            Task.detached(priority: priority) {
                do {
                    let result = try await work()
                    
                    attemptToFulfill(.success(result))
                } catch {
                    attemptToFulfill(.failure(error))
                }
            }
        }
    }
}

extension Future {
    public static func just(_ value: Result<Output, Failure>) -> Self {
        return .init { attemptToFulfill in
            attemptToFulfill(value)
        }
    }
    
    public func sinkResult(_ receiveCompletion: @escaping (Result<Output, Failure>) -> ()) -> AnyCancellable {
        sink(receiveCompletion: { completion in
            switch completion {
                case .finished:
                    break
                case .failure(let error):
                    receiveCompletion(.failure(error))
            }
        }, receiveValue: { value in
            receiveCompletion(.success(value))
        })
    }
}

extension Future where Output == Void {
    public static func perform(_ action: @escaping () -> Void) -> Self {
        return .init { attemptToFulfill in
            attemptToFulfill(.success(action()))
        }
    }
    
    public static func perform<S: Scheduler>(
        on scheduler: S,
        options: S.SchedulerOptions? = nil,
        _ action: @escaping () -> Void
    ) -> Self {
        return .init { attemptToFulfill in
            scheduler.schedule(options: options) {
                attemptToFulfill(.success(action()))
            }
        }
    }
}

extension Future where Output == Void, Failure == Never {
    public static func Error(_ action: @escaping () -> Void) -> Self {
        return .init { attemptToFulfill in
            attemptToFulfill(.success(action()))
        }
    }
    
    public static func perform<S: Scheduler>(
        on scheduler: S,
        options: S.SchedulerOptions? = nil,
        _ action: @escaping () -> Void
    ) -> Self {
        return .init { attemptToFulfill in
            scheduler.schedule(options: options) {
                attemptToFulfill(.success(action()))
            }
        }
    }
}

extension Future where Failure == Swift.Error {
    @_disfavoredOverload
    public convenience init(_ attemptToFulfill: @escaping (Promise) throws -> Void)  {
        self.init { promise in
            do {
                try attemptToFulfill(promise)
            } catch {
                promise(.failure(error))
            }
        }
    }
}

extension Future where Output == Void, Failure == Error {
    public static func perform(_ action: @escaping () -> Void) -> Self {
        return .init { attemptToFulfill in
            attemptToFulfill(.success(action()))
        }
    }

    public static func perform(_ action: @escaping () throws -> Void) -> Self {
        return .init { attemptToFulfill in
            do {
                attemptToFulfill(.success(try action()))
            } catch {
                attemptToFulfill(.failure(error))
            }
        }
    }
    
    public static func perform<S: Scheduler>(on scheduler: S, _ action: @escaping () throws -> Void) -> Self {
        return .init { attemptToFulfill in
            scheduler.schedule {
                do {
                    attemptToFulfill(.success(try action()))
                } catch {
                    attemptToFulfill(.failure(error))
                }
            }
        }
    }
}
