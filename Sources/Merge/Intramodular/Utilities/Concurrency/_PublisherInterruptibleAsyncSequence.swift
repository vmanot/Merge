//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation

fileprivate struct _PublisherInterruptibleAsyncSequence<Base: AsyncSequence, Signal: Publisher>: AsyncSequence where Signal.Output == Void, Signal.Failure == Never {
    typealias Element = Base.Element
    typealias AsyncIterator = Iterator
    
    let base: Base
    let signal: Signal
    let predicate: () async throws -> Bool
    let onInterrupt: () async throws -> Void
    
    func makeAsyncIterator() -> Iterator {
        Iterator(
            base: base.makeAsyncIterator(),
            signal: signal,
            predicate: predicate,
            onInterrupt: onInterrupt
        )
    }
    
    fileprivate final class Iterator: AsyncIteratorProtocol {
        var base: Base.AsyncIterator
        var signal: Signal
        let predicate: () async throws -> Bool
        let onInterrupt: () async throws -> Void
        
        private var subscription: AnyCancellable?
        @_OSUnfairLocked
        private var isStopped = false
        
        init(
            base: Base.AsyncIterator,
            signal: Signal,
            predicate: @escaping () async throws -> Bool,
            onInterrupt: @escaping () async throws -> Void
        ) {
            self.base = base
            self.signal = signal
            self.predicate = predicate
            self.onInterrupt = onInterrupt
            
            subscription = signal.sink(receiveValue: { [weak self] _ in
                self?.isStopped = true
            })
        }
        
        func next() async throws -> Base.Element? {
            if await _stopIfNeeded() {
                try await onInterrupt()
                
                return nil
            }
            
            let result = try await base.next()
            
            if await _stopIfNeeded() {
                try await onInterrupt()
                
                return nil
            }
            
            return result
        }
        
        private func _stopIfNeeded() async -> Bool {
            await Task.yield()
            
            let predicateResult: Bool = ((try? await predicate()) ?? true)
            
            if !predicateResult {
                isStopped = true
                
                return true
            }
            
            if isStopped {
                return true
            }
            
            return false
        }
    }
}

extension AsyncSequence {
    public func interruptible<Signal: Publisher>(
        by publisher: Signal,
        predicate: @escaping () async throws -> Bool = { true },
        onInterrupt: @escaping () async throws -> Void
    ) -> AnyAsyncSequence<Element> where Signal.Failure == Never {
        _PublisherInterruptibleAsyncSequence(
            base: self,
            signal: publisher.mapTo(()),
            predicate: predicate,
            onInterrupt: onInterrupt
        )
        .eraseToAnyAsyncSequence()
    }
}
