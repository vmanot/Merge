//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

#if swift(<5.4)
@_functionBuilder
public struct PublisherBuilder {
    
}
#else
@resultBuilder
public struct PublisherBuilder {
    
}
#endif

extension PublisherBuilder {
    public static func buildBlock<P: Publisher>(_ publisher: P) -> P {
        publisher
    }
    
    public static func buildEither<TruePublisher: Publisher, FalsePublisher: Publisher>(
        first: TruePublisher
    ) -> Either<TruePublisher, FalsePublisher> {
        .left(first)
    }
    
    public static func buildEither<TruePublisher: Publisher, FalsePublisher: Publisher>(
        second: FalsePublisher
    ) -> Either<TruePublisher, FalsePublisher> {
        .right(second)
    }
}
