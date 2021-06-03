//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

extension Publisher {
    public func then<P: Publisher>(_ publisher: P) -> AnyPublisher<P.Output, Error> {
        eraseError()
            .flatMap({ _ in publisher.eraseError() })
            .eraseToAnyPublisher()
    }
    
    public func then<P: Publisher>(
        _ publisher: P
    ) -> Publishers.FlatMap<P, Self> where P.Failure == Never {
        flatMap({ _ in publisher })
    }

    public func then<P: Publisher>(deferred createPublisher: @autoclosure @escaping () -> P) -> AnyPublisher<P.Output, Error> {
        then(Deferred(createPublisher: createPublisher))
    }
    
    public func then<P: Publisher>(
        deferred createPublisher: @escaping () -> P
    ) -> AnyPublisher<P.Output, Error> {
        then(Deferred(createPublisher: createPublisher))
    }

    public func then<P: Publisher>(
        deferred createPublisher: @escaping () -> Either<P, Combine.Empty<P.Output, P.Failure>>
    ) -> AnyPublisher<P.Output, Error> {
        then(Deferred(createPublisher: createPublisher))
    }

    public func then<P0: Publisher, P1: Publisher>(
        @PublisherBuilder deferred createPublisher: @escaping () -> Either<P0, P1>
    ) -> AnyPublisher<P0.Output, Error> where P0.Output == P1.Output, P1.Failure == P0.Failure {
        then(Deferred(createPublisher: createPublisher))
    }
}

extension Publisher {
    @_disfavoredOverload
    public func then(_ action: @escaping () -> Void) -> Publishers.Map<Self, Output> {
        map { output -> Output in
            action()
            return output
        }
    }
    
    @_disfavoredOverload
    public func then<S: Scheduler>(
        on scheduler: S,
        options: S.SchedulerOptions? = nil,
        _ action: @escaping () -> Void
    ) -> Publishers.Map<Publishers.ReceiveOn<Self, S>, Publishers.ReceiveOn<Self, S>.Output> {
        receive(on: scheduler, options: options).then(action)
    }
}

extension Publisher where Failure == Error {
    @_disfavoredOverload
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
    
    @_disfavoredOverload
    public func then<S: Scheduler>(
        on scheduler: S,
        options: S.SchedulerOptions? = nil,
        _ action: @escaping () throws -> Void
    ) -> Publishers.FlatMap<AnyPublisher<Publishers.ReceiveOn<Self, S>.Output, Error>, Publishers.ReceiveOn<Self, S>> {
        receive(on: scheduler, options: options).then(action)
    }
}
