//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension ObservableObjectPublisher {
    @inlinable
    public func publish(to publisher: ObservableObjectPublisher) -> some Publisher {
        handleOutput({ [weak publisher] in publisher?.send() })
    }
}
