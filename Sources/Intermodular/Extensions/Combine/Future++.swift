//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Combine
import Swift

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
