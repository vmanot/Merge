//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

public struct PublisherQueue<Upstream: Publisher, Context: Scheduler>: Publisher {
    public typealias Output = Upstream.Output
    public typealias Failure =  Upstream.Failure
    
    private let cancellables = Cancellables()
    private let scheduler: Context
    private let output = PassthroughSubject<Upstream.Output, Upstream.Failure>()
    
    public init(scheduler: Context) {
        self.scheduler = scheduler
    }
    
    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        output.subscribe(subscriber)
    }
    
    public func send(_ publisher: Upstream) {
        scheduler.schedule {
            publisher.receive(on: scheduler).sinkResult(storeIn: cancellables, receiveValue: {
                switch $0 {
                    case .success(let value):
                        output.send(value)
                    case .failure(let error):
                        output.send(completion: .failure(error))
                }
            })
        }
    }
}
