//
// Copyright (c) Vatsal Manot
//

#if os(macOS)

import Combine
import Foundation

extension NSLocking {
	/// Performs `body` with the lock held.
	fileprivate func withLock<Result>(_ body: () throws -> Result) rethrows -> Result {
		self.lock()
		defer { self.unlock() }
		return try body()
	}

	/// Given that the lock is held, **unlocks it**, performs `body`,
	/// then relocks it.
	///
	/// Be very careful with your thread-safety analysis when using this function!
	fileprivate func withoutLock<Result>(_ body: () throws -> Result) rethrows -> Result {
		self.unlock()
		defer { self.lock() }
		return try body()
	}
}

/// A base class for operators that are "non-synchronous", meaning that
/// one upstream value can translate to zero or more downstream values, and that
/// pending downstream values are buffered until there is demand.
///
/// This class handles all of the thread-safety guarantees needed for such an
/// operator. Subclasses need only override `receiveWhileLocked(_:)`,
/// `popValueToSendWhileLocked()`, and `hasSentAllValuesLocked`.
internal class NonSynchronousOperatorBase<Input, Downstream: Subscriber>: Subscriber, Subscription {
	// Borrowing from https://github.com/OpenCombine/OpenCombine under the MIT License.

	typealias Failure = Downstream.Failure

	/// If upstream has delivered a completion, it is stored here.
	///
	/// This is *not* cleared after the completion has been sent downstream.
	private(set) var completion: Subscribers.Completion<Failure>?

	/// Tracks whether this subscription has been cancelled.
	private(set) var hasBeenCancelled = false

	/// The lock that protects all state in this operator.
	///
	/// Why NSLock rather than the lower-level os_unfair_lock? Swift currently
	/// does not have a supported way to get the address of a stored property on
	/// a class instance *without* being treated as a mutation, which would count
	/// as violating the exclusive access restrictions if the lock were used from
	/// multiple threads at the same time. The typical workaround for this is to
	/// allocate the os_unfair_lock separately, but on Apple OSs new enough to
	/// support Combine NSLock is approximately as efficient as os_unfair_lock
	/// anyway.
	///
	/// Additionally, NSLock should "just work" (if more slowly) if Combine is
	/// ever ported to other platforms.
	private let lock = NSLock()

	private let downstream: Downstream
	private var upstreamSubscription: Subscription!

	/// Tracks whether we've sent an upstream request for more values.
	enum UpstreamDemand {
		case none, one, unlimited

		var asDemand: Subscribers.Demand {
			switch self {
			case .none: return .none
			case .one: return .max(1)
			case .unlimited: return .unlimited
			}
		}
	}

	private var upstreamDemand: UpstreamDemand

	private var pendingDownstreamDemand: Subscribers.Demand = .none
	private var isSendingToDownstream = false
	private var hasDeliveredCompletion = false

	/// Takes ownership of the downstream subscriber.
	///
	/// This does not call `receive(subscription:)` on `downstream`; that is
	/// delayed until the operator receives its upstream subscription.
	init(_ downstream: Downstream, shouldBuffer: Bool) {
		self.downstream = downstream
		self.upstreamDemand = shouldBuffer ? .unlimited : .none

		if shouldBuffer {
			precondition(self.supportsUnlimitedUpstreamDemand, "cannot buffer; \(type(of: self)) does not support unlimited upstream demand")
		}
	}

	/// Accepts input from upstream, with thread-safety provided.
	///
	/// Must be overridden by subclasses.
	func receiveWhileLocked(_ input: Input) {
		fatalError("must be overridden by subclass")
	}

	/// Produce a value to send, or `nil` if there are no values ready to send
	/// (either because the operator is waiting for upstream values, or because
	/// the upstream publisher has completed and there is nothing more to send).
	///
	/// Thread-safety is provided. Must be overridden by subclasses.
	func popValueToSendWhileLocked() -> Downstream.Input? {
		fatalError("must be overridden by subclass")
	}

	/// Given that the upstream publisher has completed, returns whether all
	/// downstream values have been flushed, i.e. whether it is time for this
	/// operator to send its own completion.
	///
	/// Thread-safety is provided. Must be overridden by subclasses.
	var hasSentAllValuesLocked: Bool {
		fatalError("must be overridden by subclass")
	}

	/// Controls whether unlimited values should ever be requested from upstream.
	///
	/// This can be used for buffering (see `init(_:shouldBuffer:)`) or for when
	/// downstream has also requested unlimited values.
	///
	/// The default is false. Subclasses that support some kind of buffering for
	/// upstream input can override it to return true. Note that this is still
	/// necessary even in the case of downstream demand being unlimited; values
	/// from upstream may arrive, asynchronously, faster than values can be sent
	/// downstream.
	///
	/// Note that this is **not** necessarily synchronized with other operations
	/// on this publisher.
	var supportsUnlimitedUpstreamDemand: Bool {
		return false
	}

	/// Controls whether a failure completion from upstream should immediately be
	/// forwarded to downstream, dropping any remaining values.
	///
	/// The Reactive Streams specification says that this should occur (item 4.2);
	/// however, particular operators may prefer to send as much data as possible
	/// before failing. The default behavior of this class is to follow the
	/// specification; subclasses may override this property to produce `false`
	/// instead.
	///
	/// - SeeAlso: [Reactive Streams v1.0.3 for Java](https://github.com/reactive-streams/reactive-streams-jvm/blob/v1.0.3/README.md#4processor-code)
	var shouldImmediatelyCompleteOnFailureLocked: Bool {
		return true
	}

	/// Releases the operator's resources upon cancellation.
	///
	/// Intended to be overridden by subclasses. The default implementation does
	/// nothing.
	func releaseResourcesWhileLocked() {
	}

	func receive(subscription: Subscription) {
		let initialUpstreamDemand: UpstreamDemand? = self.lock.withLock {
			if self.hasBeenCancelled { return nil }
			assert(self.upstreamSubscription == nil)
			self.upstreamSubscription = subscription
			return self.upstreamDemand
		}

		switch initialUpstreamDemand {
		case nil:
			// Already cancelled!
			return
		case .none?:
			// Wait for demand from downstream before sending any upstream.
			break
		case .one?:
			assertionFailure("cannot happen before downstream has received a subscription")
		case .unlimited?:
			assert(self.supportsUnlimitedUpstreamDemand, "should have been caught in initializer")
			self.upstreamSubscription.request(.unlimited)
		}

		downstream.receive(subscription: self)
	}

	final func cancel() {
		self.lock.withLock {
			self.hasBeenCancelled = true
			self.upstreamSubscription.cancel()
			self.releaseResourcesWhileLocked()
		}
	}

	/// Sends as many values as possible given the pending downstream demand and
	/// the buffered data of this operator.
	///
	/// Called uniformly by both `request(_:)` (from downstream) and `receive(_:)`
	/// (from upstream). To protect against thread unsafety and reentrancy
	/// problems, this method immediately early-exits with no pending demand if
	/// another invocation of it is currently sending values.
	private func sendAvailableValuesWhileLocked() -> UpstreamDemand {
		if self.isSendingToDownstream {
			// Avoid re-entrancy; allow the original thread to keep delivering things
			// and to decide on the final demand.
			// This is necessary because the lock is /released/ when delivering to
			// downstream, to allow re-entrancy for cancellation.
			return .none
		}
		self.isSendingToDownstream = true
		defer { self.isSendingToDownstream = false }

		func hasFailureCompletionToSendImmediately() -> Bool {
			guard case .failure? = self.completion else {
				return false
			}
			return self.shouldImmediatelyCompleteOnFailureLocked
		}

		while !self.hasBeenCancelled && self.pendingDownstreamDemand > 0 && !hasFailureCompletionToSendImmediately() {
			guard let value = self.popValueToSendWhileLocked() else {
				if self.completion != nil {
					// We've reached the end. Send our completion.
					precondition(self.hasSentAllValuesLocked, "popValue failed, hasSentAllValues is false, but upstream has completed")
					break
				}

				// We're out of values, but upstream hasn't completed yet.
				// Demand more input from upstream.
				if self.pendingDownstreamDemand == .unlimited && self.supportsUnlimitedUpstreamDemand {
					return .unlimited
				}
				return .one
			}

			self.pendingDownstreamDemand -= 1
			self.pendingDownstreamDemand += self.lock.withoutLock {
				return self.downstream.receive(value)
			}
		}

		if let completion = self.completion,
				!self.hasBeenCancelled,
				(hasFailureCompletionToSendImmediately() || self.hasSentAllValuesLocked) {
			// Only send the completion if we haven't been cancelled
			// *and* if there are no outstanding values to send.
			assert(!self.hasDeliveredCompletion)
			self.hasDeliveredCompletion = true
			self.lock.withoutLock {
				self.downstream.receive(completion: completion)
			}
		}

		return .none
	}

	final func request(_ demand: Subscribers.Demand) {
		let latestUpstreamDemand: UpstreamDemand = self.lock.withLock {
			self.pendingDownstreamDemand += demand

			// Try to satisfy the demand we just got.
			let latestUpstreamDemand = self.sendAvailableValuesWhileLocked()

			// Make sure we don't make duplicate requests; demand is cumulative!
			if latestUpstreamDemand == .none || self.upstreamDemand == latestUpstreamDemand {
				return .none
			}

			// We should only be making upstream requests if (a) we failed to satisfy
			// downstream demand, and (b) upstream has not completed yet.
			assert(self.pendingDownstreamDemand > 0)
			assert(self.completion == nil)

			self.upstreamDemand = latestUpstreamDemand
			return latestUpstreamDemand
		}

		if latestUpstreamDemand != .none {
			// This request is performed unlocked because it may be satisfied
			// synchronously. This is safe because we either request one
			// item at a time, which means we know there's currently 0 pending
			// upstream demand and therefore receive(_:) won't be called before we can
			// send this request, or we're requesting unlimited items and it doesn't
			// matter if we over-request.
			self.upstreamSubscription.request(latestUpstreamDemand.asDemand)
		}
	}

	final func receive(_ input: Input) -> Subscribers.Demand {
		return self.lock.withLock {
			self.receiveWhileLocked(input)

			// See if the value we just got can satisfy outstanding demand.
			let latestUpstreamDemand = self.sendAvailableValuesWhileLocked()

			// If there's still outstanding downstream demand, demand another value
			// from upstream.
			if self.upstreamDemand != .unlimited {
				self.upstreamDemand = latestUpstreamDemand
			}
			return latestUpstreamDemand.asDemand
		}
	}

	func receive(completion: Subscribers.Completion<Failure>) {
		self.lock.withLock {
			self.completion = completion

			// Send the completion we just got if it's appropriate to do so.
			let upstreamDemand = self.sendAvailableValuesWhileLocked()
			assert(upstreamDemand == .none)
		}
	}
}

#endif
