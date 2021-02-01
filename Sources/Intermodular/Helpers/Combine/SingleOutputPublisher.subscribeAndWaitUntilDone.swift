//
// Copyright (c) Vatsal Manot
//

import Dispatch
import Swallow

extension SingleOutputPublisher {
    public func subscribeAndWaitUntilDone() -> Result<Output, Failure> {
        var result: Result<Output, Failure>?
        let queue = DispatchQueue(qosClass: .current)
        let done = DispatchWorkItem(qos: .unspecified, flags: .inheritQoS, block: { })
        
        self.handleEvents(receiveCancel: { queue.async(execute: done) })
            .receive(on: queue)
            .receive(
                subscriber: Subscribers.Sink(
                    receiveCompletion: { completion in
                        switch completion {
                            case .finished:
                                break
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
        
        return result!
    }
    
    public func subscribeAndWaitUntilDone() -> Output where Failure == Never {
        guard case .success(let value) = (subscribeAndWaitUntilDone() as Result<Output, Never>) else {
            fatalError(reason: .irrational)
        }
        
        return value
    }
}
