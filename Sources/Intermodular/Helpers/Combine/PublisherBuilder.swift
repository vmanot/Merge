//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow
import SwiftUI

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
    public static func buildBlock<Output, Failure>() -> Combine.Empty<Output, Failure> {
        .init()
    }
    
    public static func buildBlock<P: Publisher>(_ publisher: P) -> P {
        publisher
    }
    
    public static func buildIf<P: Publisher>(_ publisher: P?) -> Either<P, Combine.Empty<P.Output, P.Failure>> {
        if let publisher = publisher {
            return .left(publisher)
        } else {
            return .right(Empty())
        }
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
