//
// Copyright (c) Vatsal Manot
//

import Combine
import Runtime

// Once it is possible to express conformance to a non-throwing async sequence we should create a new type
// `AsyncSequencePublisher<S: nothrow AsyncSequence>`. At the moment the safest thing to do is capture the error and
// allow the consumer to ignore it if they wish
public struct AsyncSequencePublisher<Base: AsyncSequence, Failure: Error>: Combine.Publisher {
    public typealias Output = Base.Element
    
    private var sequence: Base
    
    public init(_ sequence: Base) {
        self.sequence = sequence
    }
    
    public func receive<_S: Subscriber<Output, Failure>>(
        subscriber: _S
    ) {
        subscriber.receive(
            subscription: Subscription(subscriber: subscriber, sequence: sequence)
        )
    }
    
    final class Subscription<
        Subscriber: Combine.Subscriber
    >: Combine.Subscription where Subscriber.Input == Output, Subscriber.Failure == Failure {
        
        private var sequence: Base
        private var subscriber: Subscriber
        private var isCancelled = false
        
        private var lock = OSUnfairLock()
        private var demand: Subscribers.Demand = .none
        private var task: Task<Void, Error>?
        
        init(subscriber: Subscriber, sequence: Base) {
            self.sequence = sequence
            self.subscriber = subscriber
        }
        
        func request(_ __demand: Subscribers.Demand) {
            precondition(__demand > 0)
            
            lock.withCriticalScope {
                demand = __demand
            }
            
            guard task.isNil else {
                return
            }
            
            lock.acquireOrBlock()
            
            defer {
                lock.relinquish()
            }
            
            task = Task {
                var iterator = lock.withCriticalScope {
                    sequence.makeAsyncIterator()
                }
                
                while lock.withCriticalScope({ !isCancelled && demand > 0 }) {
                    let element: Base.Element?
                    
                    do {
                        element = try await iterator.next()
                    } catch is CancellationError {
                        lock.withCriticalScope {
                            subscriber
                        }
                        .receive(completion: .finished)
                        
                        return
                    } catch let error as Failure {
                        lock.withCriticalScope {
                            subscriber
                        }
                        .receive(completion: .failure(error))
                        
                        throw CancellationError()
                    } catch {
                        assertionFailure("Expected \(Failure.self) but got \(type(of: error))")
                        
                        throw CancellationError()
                    }
                    
                    guard let element else {
                        lock.withCriticalScope {
                            subscriber
                        }
                        .receive(completion: .finished)
                        
                        throw CancellationError()
                    }
                    
                    try Task.checkCancellation()
                    
                    lock.withCriticalScope {
                        demand -= 1
                    }
                    
                    let newDemand = lock.withCriticalScope {
                        subscriber
                    }.receive(element)
                    
                    lock.withCriticalScope {
                        demand += newDemand
                    }
                    
                    await Task.yield()
                }
                
                task = nil
            }
        }
        
        func cancel() {
            lock.withCriticalScope {
                task?.cancel()
                isCancelled = true
            }
        }
    }
}

// MARK: - Supplementary

extension AsyncSequence {
    public func publisher() -> AsyncSequencePublisher<Self, Error> {
        AsyncSequencePublisher(self)
    }
}

extension AsyncStream {
    public func publisher() -> AsyncSequencePublisher<Self, Never> {
        AsyncSequencePublisher(self)
    }
}

extension AsyncThrowingStream {
    public func publisher() -> AsyncSequencePublisher<Self, Failure> {
        AsyncSequencePublisher(self)
    }
}
