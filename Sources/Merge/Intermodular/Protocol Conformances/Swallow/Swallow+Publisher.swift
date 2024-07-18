//
// Copyright (c) Vatsal Manot
//

import Combine
import Swallow

extension Either: Combine.Publisher where
    LeftValue: Publisher,
    RightValue: Publisher,
    LeftValue.Output == RightValue.Output,
    LeftValue.Failure == RightValue.Failure
{
    public typealias Output = LeftValue.Output
    public typealias Failure = LeftValue.Failure
    
    public func receive<S: Subscriber>(
        subscriber: S
    ) where S.Failure == Failure, S.Input == Output {
        switch self {
            case .left(let publisher):
                publisher.receive(subscriber: subscriber)
            case .right(let publisher):
                publisher.receive(subscriber: subscriber)
        }
    }
    
    public init(@PublisherBuilder _ createPublisher: () -> Either<LeftValue, RightValue>) {
        self = createPublisher()
    }
}

extension Either: Merge.SingleOutputPublisher where
    LeftValue: SingleOutputPublisher,
    RightValue: SingleOutputPublisher,
    LeftValue.Output == RightValue.Output,
    LeftValue.Failure == RightValue.Failure
{
    
}
