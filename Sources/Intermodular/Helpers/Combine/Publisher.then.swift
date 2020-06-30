//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publisher {
    public func then<P: Publisher>(_ publisher: P) -> AnyPublisher<P.Output, Error> {
        eraseError()
            .flatMap({ _ in publisher.eraseError() })
            .eraseToAnyPublisher()
    }
    
    public func then<P: Publisher>(deferred createPublisher: @autoclosure @escaping () -> P) -> AnyPublisher<P.Output, Error> {
        then(Deferred(createPublisher: createPublisher))
    }
    
    public func then<P: Publisher>(deferred createPublisher: @escaping () -> P) -> AnyPublisher<P.Output, Error> {
        then(Deferred(createPublisher: createPublisher))
    }
    
    public func then(_ action: @escaping () -> Void) -> Publishers.Map<Self, Output> {
        map { output -> Output in
            action()
            return output
        }
    }
    
    public func then<S: Scheduler>(
        on scheduler: S,
        options: S.SchedulerOptions? = nil,
        _ action: @escaping () -> Void
    ) -> Publishers.Map<Publishers.ReceiveOn<Self, S>, Publishers.ReceiveOn<Self, S>.Output> {
        receive(on: scheduler, options: options).then(action)
    }
}

extension Publisher where Failure == Never {
    public func then<P: Publisher>(
        _ publisher: P
    ) -> Publishers.FlatMap<P, Self> where P.Failure == Never {
        flatMap({ _ in publisher })
    }
}

extension Publisher where Failure == Error {
    public func then(_ action: @escaping () throws -> Void) -> Publishers.FlatMap<AnyPublisher<Self.Output, Error>, Self> {
        flatMap { output -> AnyPublisher<Output, Error> in
            do {
                try action()
                
                return Just(output).setFailureType(to: Error.self).eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
    }
    
    public func then<S: Scheduler>(
        on scheduler: S,
        options: S.SchedulerOptions? = nil,
        _ action: @escaping () throws -> Void
    ) -> Publishers.FlatMap<AnyPublisher<Publishers.ReceiveOn<Self, S>.Output, Error>, Publishers.ReceiveOn<Self, S>> {
        receive(on: scheduler, options: options).then(action)
    }
}
