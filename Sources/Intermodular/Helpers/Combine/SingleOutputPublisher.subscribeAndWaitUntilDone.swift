//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Swallow

extension SingleOutputPublisher {
    /// Synchronously subscribe to the publisher and wait on the current thread until it finishes.
    ///
    /// This function blocks the calling thread until the publisher emits a completion event.
    @discardableResult
    public func subscribeAndWaitUntilDone(
        on queue: DispatchQueue? = nil
    ) -> Result<Output, Failure>? {
        var result: Result<Output, Failure>?
        let queue = queue ?? DispatchQueue(qosClass: .current)
        let done = DispatchWorkItem(qos: .unspecified, flags: .inheritQoS, block: { })
        
        self
            .handleEvents(receiveCancel: { queue.async(execute: done) })
            .subscribe(on: queue)
            .receive(on: queue)
            .receive(
                subscriber: Subscribers.Sink(
                    receiveCompletion: { completion in
                        switch completion {
                            case .finished:
                                if result == nil {
                                    queue.async(execute: done)
                                }
                            case .failure(let error):
                                result = .failure(error)
                                
                                queue.async(execute: done)
                        }
                    },
                    receiveValue: { value in
                        result = .success(value)
                        
                        queue.async(execute: done)
                    }
                )
            )
        
        done.wait()
        
        return result
    }
    
    /// Synchronously subscribe to the publisher and wait on the current thread until it finishes.
    ///
    /// This function blocks the calling thread until the publisher emits a completion event.
    public func subscribeAndWaitUntilDone() -> Output? where Failure == Never {
        guard let result = (subscribeAndWaitUntilDone() as Result<Output, Never>?) else {
            return nil
        }
        
        guard case .success(let value) = (result as Result<Output, Never>) else {
            fatalError(reason: .irrational)
        }
        
        return value
    }
}
