//
// Copyright (c) Vatsal Manot
//

import Foundation
import Swallow

public final class AsyncPassthroughStream<Element>: AsyncSequence, @unchecked Sendable {
    fileprivate typealias Base = AsyncStream<Element>
    
    private typealias ContinuationID = UUID
    private typealias Continuation = Base.Continuation
    
    private let mutex = OSUnfairLock()
    
    private var continuations = [ContinuationID: Continuation]()
    
    public init() {
        
    }
    
    deinit {
        self.finish()
    }
    
    public func send(_ value: Element) {
        mutex.withCriticalScope {
            continuations.values.forEach {
                $0.yield(value)
            }
        }
    }
    
    public func finish() {
        mutex.withCriticalScope {
            continuations.values.forEach {
                $0.finish()
            }
            
            continuations.removeAll()
        }
    }
    
    private func removeContinuation(
        _ continuation: ContinuationID
    ) {
        mutex.withCriticalScope {
            continuations[continuation]?.finish()
            continuations[continuation] = nil
        }
    }
}

// MARK: - Iterator

extension AsyncPassthroughStream {
    private func _makeAsyncIterator() async -> Iterator {
        let id = ContinuationID()
        
        let (stream, continuation) = await AsyncStream<Element>.streamWithContinuation()
        
        mutex.withCriticalScope {
            continuations[id] = continuation
            
            continuation.onTermination = { [weak self] _ in
                self?.removeContinuation(id)
            }
        }
        
        return Iterator(
            stream.makeAsyncIterator(),
            onTermination: { [weak self] in
                self?.removeContinuation(id)
            }
        )
    }
    
    private struct Iterator: AsyncIteratorProtocol {
        private var iterator: Base.Iterator
        private let onTermination: () -> Void
        
        init(
            _ iterator: Base.Iterator,
            onTermination: @escaping () -> Void
        ) {
            self.iterator = iterator
            
            self.onTermination = onTermination
        }
        
        mutating func next() async -> Element? {
            guard !Task.isCancelled else {
                onTermination()
                
                return nil
            }
            
            let next = await iterator.next()
            
            if next == nil {
                onTermination()
            }
            
            return next
        }
    }
    
    public func makeAsyncIterator() -> AnyAsyncIterator<Element> {
        AnyAsyncIterator(
            _DeferredAsyncIterator { [weak self] in
                try await self.unwrap()._makeAsyncIterator()
            }
        )
    }
    
    public func makeAsyncIterator() async -> AnyAsyncIterator<Element> {
        await AnyAsyncIterator(_makeAsyncIterator())
    }
}

// MARK: - AsyncStream

extension AsyncPassthroughStream {
    /// Creates an asynchronous sequence that produce new elements over time.
    public func makeAsyncStream() -> AsyncStream<Element> {
        AsyncStream(self)
    }
}
