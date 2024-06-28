//
// Copyright (c) Vatsal Manot
//

import Combine
import Foundation
import Swift

/// A `ReplaySubject` is a subject that can buffer one or more values.
///
/// It stores value events, up to its `bufferSize` in a first-in-first-out manner and then replays it to future subscribers and also forwards completion events.
public final class ReplaySubject<Output, Failure: Error>: Subject {
    public typealias Output = Output
    public typealias Failure = Failure

    private let lock = NSRecursiveLock()

    private let bufferSize: Int
    private var buffer = [Output]()
    private var subscriptions = [Subscription<AnySubscriber<Output, Failure>>]()
    private var completion: Subscribers.Completion<Failure>?

    private var isActive: Bool {
        completion == nil
    }

    /// Create a `ReplaySubject`, buffering up to `bufferSize` values and replaying them to new subscribers.
    ///
    /// - Parameter bufferSize: The maximum number of value events to buffer and replay to all future subscribers.
    public init(bufferSize: Int = Int.max) {
        self.bufferSize = bufferSize
    }

    public func send(_ value: Output) {
        let subscriptions: [Subscription<AnySubscriber<Output, Failure>>]

        do {
            lock.acquireOrBlock()

            defer {
                lock.relinquish()
            }

            guard isActive else {
                return
            }

            buffer.append(value)

            if buffer.count > bufferSize {
                buffer.removeFirst()
            }

            subscriptions = self.subscriptions
        }

        subscriptions.forEach({ $0.forwardToBuffer(value) })
    }

    public func send(completion: Subscribers.Completion<Failure>) {
        let subscriptions: [Subscription<AnySubscriber<Output, Failure>>]

        do {
            lock.acquireOrBlock()

            defer {
                lock.relinquish()
            }

            guard isActive else { return }

            self.completion = completion

            subscriptions = self.subscriptions
        }

        subscriptions.forEach({ $0.forwardToBuffer(completion: completion) })
    }

    public func send(subscription: Combine.Subscription) {
        subscription.request(.unlimited)
    }

    public func receive<Subscriber: Combine.Subscriber>(subscriber: Subscriber) where Failure == Subscriber.Failure, Output == Subscriber.Input {
        let subscriberIdentifier = subscriber.combineIdentifier

        let subscription = Subscription(downstream: AnySubscriber(subscriber)) { [weak self] in
            self?.removeSubscriber(withIdentifier: subscriberIdentifier)
        }

        let buffer: [Output]
        let completion: Subscribers.Completion<Failure>?

        do {
            lock.acquireOrBlock()

            defer {
                lock.relinquish()
            }

            subscriptions.append(subscription)

            buffer = self.buffer
            completion = self.completion
        }

        subscriber.receive(subscription: subscription)

        subscription.replay(buffer, completion: completion)
    }

    private func removeSubscriber(withIdentifier subscriberIdentifier: CombineIdentifier) {
        lock.acquireOrBlock()

        defer {
            lock.relinquish()
        }

        subscriptions.removeAll(where: { $0.downstreamCombineIdentifier == subscriberIdentifier })
    }
}

// MARK: - API

extension Publisher {
    /// Provides a subject that shares a single subscription to the upstream publisher and replays at most `bufferSize` items emitted by that publisher
    ///
    /// - Parameter bufferSize: limits the number of items that can be replayed
    public func shareReplay(_ bufferSize: Int) -> AnyPublisher<Output, Failure> {
        multicast(subject: ReplaySubject(bufferSize: bufferSize)).autoconnect().eraseToAnyPublisher()
    }
}

// MARK: - Auxiliary

extension ReplaySubject {
    private final class Subscription<Downstream: Subscriber>: Combine.Subscription where Output == Downstream.Input, Failure == Downstream.Failure {
        let downstreamCombineIdentifier: CombineIdentifier

        private var demandBuffer: DemandBuffer<Downstream>?
        private var onCancel: (() -> Void)?

        init(downstream: Downstream, onCancel: (() -> Void)?) {
            self.downstreamCombineIdentifier = downstream.combineIdentifier
            self.demandBuffer = DemandBuffer(subscriber: downstream)
            self.onCancel = onCancel
        }

        func request(_ demand: Subscribers.Demand) {
            _ = demandBuffer?.demand(demand)
        }

        func cancel() {
            onCancel?()
            onCancel = nil

            demandBuffer = nil
        }

        func replay(_ buffer: [Output], completion: Subscribers.Completion<Failure>?) {
            buffer.forEach(forwardToBuffer)

            if let completion = completion {
                forwardToBuffer(completion: completion)
            }
        }

        func forwardToBuffer(_ value: Output) {
            _ = demandBuffer?.buffer(value: value)
        }

        func forwardToBuffer(completion: Subscribers.Completion<Failure>) {
            demandBuffer?.complete(completion: completion)

            cancel()
        }
    }
}
