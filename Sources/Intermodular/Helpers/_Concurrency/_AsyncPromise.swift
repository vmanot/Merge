//
// Copyright (c) Vatsal Manot
//

import Swallow

public actor _AsyncPromise<Success, Failure: Error> {
    private typealias _FulfilledValue = Result<Success, Failure>
    
    private enum _Error: Swift.Error {
        case promiseAlreadyFulfilled
    }
    
    private var suspensions: [UnsafeContinuation<_FulfilledValue, Never>] = []
    
    private let _fulfilledValue = MutexProtected<_FulfilledValue?, OSUnfairLock>()
    
    private nonisolated var fulfilledValue: _FulfilledValue? {
        get {
            self._fulfilledValue.assignedValue
        } set {
            self._fulfilledValue.withCriticalRegion {
                $0 = newValue
            }
        }
    }
    
    public nonisolated var isFulfilled: Bool {
        fulfilledValue != nil
    }
    
    public init() {
        
    }
    
    public init(_ value: Success) {
        self.fulfilledValue = .success(value)
    }
    
    public func fulfill(with result: Result<Success, Failure>) {
        guard fulfilledValue == nil else {
            assertionFailure(_Error.promiseAlreadyFulfilled)
            
            return
        }
        
        fulfilledValue = result
        
        suspensions.forEach({ $0.resume(with: .success(result)) })
    }
    
    public func fulfill(with success: Success) {
        fulfill(with: .success(success))
    }
    
    public func fulfill(with failure: Failure) {
        fulfill(with: .failure(failure))
    }
    
    public func result() async -> Result<Success, Failure> {
        if let fulfilledValue {
            return fulfilledValue
        }
        
        return await withUnsafeContinuation { continuation in
            if let fulfilledValue = fulfilledValue {
                continuation.resume(with: .success(fulfilledValue))
            } else {
                self.suspensions.append(continuation)
            }
        }
    }
    
    public func get() async throws -> Success {
        try await result().get()
    }
    
    public func get() async -> Success where Failure == Never {
        await self.result().get()
    }
}
