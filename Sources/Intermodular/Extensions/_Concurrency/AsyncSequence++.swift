//
// Copyright (c) Vatsal Manot
//

import Swallow

extension AsyncSequence {
    public func first() async rethrows -> Element? {
        try await first { _ in true }
    }

    public func eraseToThrowingStream() -> AsyncThrowingStream<Element, Error> {
        AsyncThrowingStream(self)
    }
}
