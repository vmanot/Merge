//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

/// A single-output publisher that performs type erasure by wrapping another single-output publisher.
public struct AnySingleOutputPublisher<Output, Failure: Error>: SingleOutputPublisher {
    public let base: AnyPublisher<Output, Failure>
    
    public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        base.receive(subscriber: subscriber)
    }
}

// MARK: - API

extension AnySingleOutputPublisher {
    public init<P: Publisher>(_unsafe publisher: P) where P.Output == Output, P.Failure == Failure {
        self.base = publisher.eraseToAnyPublisher()
    }
    
    public init<P: SingleOutputPublisher>(_ publisher: P) where P.Output == Output, P.Failure == Failure {
        self.base = publisher.eraseToAnyPublisher()
    }
}

extension AnySingleOutputPublisher {
    public static func result(_ result: Result<Output, Failure>) -> Self {
        AnyPublisher.result(result)._unsafe_eraseToAnySingleOutputPublisher()
    }
    
    public static func just(_ output: Output) -> Self {
        AnyPublisher.just(output)._unsafe_eraseToAnySingleOutputPublisher()
    }
    
    public static func failure(_ failure: Failure) -> Self {
        AnyPublisher.failure(failure)._unsafe_eraseToAnySingleOutputPublisher()
    }
}

extension Publisher {
    public func _unsafe_eraseToAnySingleOutputPublisher() -> AnySingleOutputPublisher<Output, Failure> {
        .init(_unsafe: self)
    }
}

extension SingleOutputPublisher {
    public func eraseToAnySingleOutputPublisher() -> AnySingleOutputPublisher<Output, Failure> {
        .init(self)
    }
}
