//
// Copyright (c) Vatsal Manot
//

import Combine
import FoundationX
import Swift

/// A `Publisher` guaranteed to publish no more than one element.
///
/// Single-output publishers can also complete without emitting any elements.
public protocol SingleOutputPublisher: Publisher {
    
}

// MARK: - API

extension SingleOutputPublisher {
    /// Asynchronously runs this publisher and awaits its output.
    public func output() async throws -> Output {
        let cancellable = SingleAssignmentAnyCancellable()
        let didReceiveValue = _LockedState<Bool>(initialState: false)
        
        let result: Output = try await withCheckedThrowingContinuation { continuation in
            cancellable.set(
                sink(
                    receiveCompletion: { completion in
                        switch completion {
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            case .finished:
                                if !didReceiveValue.withLock({ $0 }) {
                                    continuation.resume(
                                        throwing: CancellationError()
                                    )
                                }
                        }
                    },
                    receiveValue: { value in
                        didReceiveValue.withLock { didReceiveValue in
                            guard !didReceiveValue else {
                                assertionFailure("received more than one element")
                                
                                return
                            }
                            
                            didReceiveValue = true
                            
                            continuation.resume(returning: value)
                        }
                    }
                )
            )
        }

        cancellable.cancel()
        
        return try didReceiveValue.withLock { didReceiveValue in
            if didReceiveValue {
                return result
            } else {
                throw CancellationError()
            }
        }
    }
}

// MARK: - Conformances

extension Deferred: SingleOutputPublisher where DeferredPublisher: SingleOutputPublisher {
    
}

extension Fail: SingleOutputPublisher {
    
}

extension Future: SingleOutputPublisher {
    
}

extension Just: SingleOutputPublisher {
    
}

extension Publishers.Autoconnect: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Catch: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Collect: SingleOutputPublisher {
    
}

extension Publishers.Decode: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Encode: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.First: SingleOutputPublisher {
    
}

extension Publishers.FirstWhere: SingleOutputPublisher {
    
}

extension Publishers.FlatMap: SingleOutputPublisher where Upstream: SingleOutputPublisher, NewPublisher: SingleOutputPublisher {
    
}

extension Publishers.HandleEvents: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Last: SingleOutputPublisher {
    
}

extension Publishers.Map: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.MapError: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Print: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.ReceiveOn: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Reduce: SingleOutputPublisher {
    
}

extension Publishers.SetFailureType: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.SubscribeOn: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.Timeout: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Publishers.TryFirstWhere: SingleOutputPublisher {
    
}

extension Publishers.TryMap: SingleOutputPublisher where Upstream: SingleOutputPublisher {
    
}

extension Result.Publisher: SingleOutputPublisher {
    
}

extension URLSession.DataTaskPublisher: SingleOutputPublisher {
    
}
