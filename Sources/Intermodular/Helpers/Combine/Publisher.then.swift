//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

extension Publisher {
    public func then<P: Publisher>(_ publisher: P) -> AnyPublisher<P.Output, Error> {
        map({ Either<Output, P.Output>.left($0) })
            .eraseError()
            .append(publisher.eraseError().map({ Either<Output, P.Output>.right($0) }))
            .compactMap({ $0.rightValue })
            .eraseToAnyPublisher()
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
    
    @_disfavoredOverload
    public func then(_ action: @escaping () -> Void) -> AnyPublisher<Void, Error> {
        then(deferred: Just(action()))
    }
    
    @_disfavoredOverload
    public func then<S: Scheduler>(
        on scheduler: S,
        options: S.SchedulerOptions? = nil,
        _ action: @escaping () -> Void
    ) -> AnyPublisher<Void, Error> {
        receive(on: scheduler, options: options).then(action)
    }
}
