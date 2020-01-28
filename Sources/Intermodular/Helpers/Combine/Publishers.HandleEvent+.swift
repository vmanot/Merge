//
// Copyright (c) Vatsal Manot
//

import Combine
import Swift

extension Publisher {
    /// Performs the specified closure upon completion.
    public func handleCompletion(
        _ receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> ()
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(
            receiveSubscription: nil,
            receiveOutput: nil,
            receiveCompletion: receiveCompletion,
            receiveCancel: nil,
            receiveRequest: nil
        )
    }
    
    /// Performs the specified closure upon cancellation.
    public func handleCancel(
        _ receiveCancel: @escaping () -> ()
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(
            receiveSubscription: nil,
            receiveOutput: nil,
            receiveCompletion: nil,
            receiveCancel: receiveCancel,
            receiveRequest: nil
        )
    }
    
    /// Performs the specified closure upon output.
    public func handleOutput(
        _ receiveOutput: @escaping (Output) -> ()
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(
            receiveSubscription: nil,
            receiveOutput: receiveOutput,
            receiveCompletion: nil,
            receiveCancel: nil,
            receiveRequest: nil
        )
    }
        
    public func handleOutput<P: Publisher>(
        _ receiveOutput: @escaping (Output) -> P
    ) -> AnyPublisher<Output, Failure> where P.Failure == Never {
        flatMap { output in
            receiveOutput(output)
                .setFailureType(to: Failure.self)
                .mapTo(output)
        }
        .eraseToAnyPublisher()
    }
    
    /// Performs the specified closure upon request.
    public func handleRequest(
        _ receiveRequest: @escaping (Subscribers.Demand) -> ()
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(
            receiveSubscription: nil,
            receiveOutput: nil,
            receiveCompletion: nil,
            receiveCancel: nil,
            receiveRequest: receiveRequest
        )
    }
    
    /// Performs the specified closure upon receipt of subscription.
    public func handleSubscription(
        _ receiveSubscription: @escaping (Subscription) -> ()
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(
            receiveSubscription: receiveSubscription,
            receiveOutput: nil,
            receiveCompletion: nil,
            receiveCancel: nil,
            receiveRequest: nil
        )
    }
}

extension Publisher {
    public func onOutput(do action: @autoclosure @escaping () -> Void) -> Publishers.HandleEvents<Self> {
        handleOutput({ _ in action() })
    }
    
    public func handleCancelOrCompletion(
        _ receiveCancelOrCompletion: @escaping (Subscribers.Completion<Failure>?) -> ()
    )  -> Publishers.HandleEvents<Self> {
        handleEvents(
            receiveCompletion: { receiveCancelOrCompletion($0) },
            receiveCancel: { receiveCancelOrCompletion(nil) }
        )
    }
}

extension Publisher where Failure == Error {
    public func handleOutput<P: Publisher>(
        _ receiveOutput: @escaping (Output) -> P
    ) -> AnyPublisher<Output, Failure> {
        flatMap { output in
            receiveOutput(output)
                .eraseError()
                .mapTo(output)
        }
        .eraseToAnyPublisher()
    }
}
