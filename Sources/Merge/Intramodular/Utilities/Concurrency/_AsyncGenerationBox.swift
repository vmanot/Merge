//
// Copyright (c) Vatsal Manot
//

import Swallow

public final class _AsyncGenerationBox<Success, Failure: Error>: @unchecked Sendable {
    public typealias FulfilledValue = Result<Success, Failure>
    
    private let lock = OSUnfairLock()
    
    private let _generationIterator: MonotonicallyIncreasingID
    
    private var _lastGeneration: AnyHashable?
    private var _currentGeneration: AnyHashable
    private var _promises: [AnyHashable: _AsyncPromise<Success, Failure>]
    
    public var lastValue: FulfilledValue? {
        lock.withCriticalScope {
            _lastGeneration.flatMap({ _promises[$0] })?.fulfilledResult
        }
    }
    
    public init() {
        self._generationIterator = MonotonicallyIncreasingID()
        self._lastGeneration = nil
        self._currentGeneration = self._generationIterator.next()
        self._promises = [:]
    }
    
    public func fulfill(
        with result: Result<Success, Failure>
    ) {
        lock.withCriticalScope {
            guard let promise = _promises[_currentGeneration] else {
                return
            }
            
            promise.fulfill(with: result)
            
            if let _lastGeneration {
                _promises.removeValue(forKey: _lastGeneration)
            }
            
            _incrementGeneration()
        }
    }
    
    private func _incrementGeneration() {
        _lastGeneration = _currentGeneration
        _currentGeneration = _generationIterator.next()
    }
    
    public func result() async -> Result<Success, Failure> {
        let promise = lock.withCriticalScope {
            _promises[_currentGeneration, defaultInPlace: .init()]
        }
        
        return await promise.result()
    }
}

// MARK: - Extensions -

extension _AsyncGenerationBox {
    public func fulfill(with success: Success) {
        fulfill(with: .success(success))
    }
    
    public func fulfill(with failure: Failure) {
        fulfill(with: .failure(failure))
    }
    
    public func get() async throws -> Success {
        try await result().get()
    }
    
    public func get() async -> Success where Failure == Never {
        await self.result().get()
    }
}

// MARK: - Conformances

extension _AsyncGenerationBox: Cancellable where Failure == Error {
    public func cancel() {
        _promises.values.forEach({ $0.cancel() })
    }
}

// MARK: - Error Handling

extension _AsyncGenerationBox {
    fileprivate enum _Error: Swift.Error {
        case promiseAlreadyFulfilled
    }
}

// MARK: - Auxiliary

private class MonotonicallyIncreasingID {
    private var currentValue: Int64 = 0
    
    public func next() -> AnyHashable {
        currentValue += 1
        return currentValue
    }
}
