//
// Copyright (c) Vatsal Manot
//

import Swallow

extension AsyncStream {
    public init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
        var iterator: S.AsyncIterator?
        
        self.init {
            if iterator == nil {
                iterator = sequence.makeAsyncIterator()
            }
            
            return try? await iterator?.next()
        }
    }
    
    public static func streamWithContinuation(
        _ elementType: Element.Type = Element.self,
        bufferingPolicy limit: Continuation.BufferingPolicy = .unbounded
    ) async -> (stream: Self, continuation: Continuation) {
        await withUnsafeContinuation { continuationContinuation in
            return Self(elementType, bufferingPolicy: limit) {
                continuationContinuation.resume(returning: $0)
            }
        }
    }
    
    /// An `AsyncStream` that never emits and never completes unless cancelled.
    public static var never: Self {
        Self { _ in }
    }
    
    /// An `AsyncStream` that never emits and completes immediately.
    public static var finished: Self {
        Self { $0.finish() }
    }
}

extension AsyncSequence {
    public func eraseToStream() -> AsyncStream<Element> {
        AsyncStream(self)
    }
}
