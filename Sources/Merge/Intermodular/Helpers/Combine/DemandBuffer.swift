//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swift

final class DemandBuffer<S: Subscriber> {
    private let subscriber: S
    private var completion: Subscribers.Completion<S.Failure>?
    private let lock = NSRecursiveLock()
    private var buffer = [S.Input]()
    private var demandState = Demand()
    
    /// Initialize a new demand buffer for a provided downstream subscriber.
    ///
    /// - Parameter subscriber: The downstream subscriber demanding events.
    init(subscriber: S) {
        self.subscriber = subscriber
    }
}

extension DemandBuffer {
    
    /// Buffer an upstream value to later be forwarded to the downstream subscriber, once it demands it.
    ///
    /// - Parameter value: Upstream value to buffer.
    /// - Returns: The demand fulfilled by the bufferr.
    func buffer(value: S.Input) -> Subscribers.Demand {
        precondition(self.completion == nil, "A completed publisher cannot send further values.")
        lock.acquireOrBlock()
        
        defer {
            lock.relinquish()
        }
        
        switch demandState.requested {
            case .unlimited:
                return subscriber.receive(value)
            default:
                buffer.append(value)
                return flush()
        }
    }
    
    /// Complete the demand buffer with an upstream completion event.
    ///
    /// This method will deplete the buffer immediately, based on the currently accumulated demand, and relay the completion event down as soon as demand is fulfilled.
    ///
    /// - Parameter completion: Completion event.
    func complete(completion: Subscribers.Completion<S.Failure>) {
        precondition(self.completion == nil, "A completion has already occured.")
        
        self.completion = completion
        
        flush()
    }
    
    /// Signal to the buffer that the downstream requested new demand.
    ///
    /// - Note: The buffer will attempt to flush as many events rqeuested by the downstream at this point.
    func demand(_ demand: Subscribers.Demand) -> Subscribers.Demand {
        flush(adding: demand)
    }
}

extension DemandBuffer {
    /// Flush buffered events to the downstream based on the current state of the downstream's demand.
    ///
    /// - Parameter newDemand: The new demand to add. If `nil`, the flush isn't the result of an explicit demand change.
    ///
    /// - Note: After fulfilling the downstream's request, if completion has already occured, the buffer will be cleared and the completion event will be sent to the downstream subscriber.
    @discardableResult
    private func flush(adding newDemand: Subscribers.Demand? = nil) -> Subscribers.Demand {
        lock.acquireOrBlock()
        
        defer {
            lock.relinquish()
        }
        
        if let newDemand = newDemand {
            demandState.requested += newDemand
        }
        
        // If the buffer isn't ready for flushing, return immediately.
        guard demandState.requested > 0 || newDemand == Subscribers.Demand.none else { return .none }
        
        while !buffer.isEmpty && demandState.processed < demandState.requested {
            demandState.requested += subscriber.receive(buffer.remove(at: 0))
            demandState.processed += 1
        }
        
        if let completion = completion {
            // A completion event was already sent.
            buffer = []
            demandState = .init()
            
            self.completion = nil
            
            subscriber.receive(completion: completion)
            
            return .none
        }
        
        let sentDemand = demandState.requested - demandState.sent
        
        demandState.sent += sentDemand
        
        return sentDemand
    }
}

extension DemandBuffer {
    /// A model that tracks the downstream's accumulated demand state.
    private struct Demand {
        var processed: Subscribers.Demand = .none
        var requested: Subscribers.Demand = .none
        var sent: Subscribers.Demand = .none
    }
}
