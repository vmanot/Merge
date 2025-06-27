//
// Copyright (c) Vatsal Manot
//

import Combine
#if canImport(Observation)
import Observation
#endif
import Swallow

@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
public func _withContinuousObservationTracking(
    applying block: @escaping () -> Void,
    onChange: @autoclosure () -> @Sendable () -> Void,
    isolation: isolated (any Actor)? = #isolation
) -> _ContinuousObservationTrackingSubscription {
    let isCancelled = Swallow._OSUnfairLocked<Bool>.init(initialState: false)
    let _onChange: @Sendable () -> Void = onChange()
    
    __internal_withContinuousObservationTracking(
        applying: block,
        isCancelled: isCancelled,
        onChange: _onChange
    )
    
    return _ContinuousObservationTrackingSubscription {
        isCancelled.withLock({ $0 = true })
    }
}

public func _withContinuousObservationTrackingIfAvailable(
    applying block: @escaping () -> Void,
    onChange: @autoclosure () -> @Sendable () -> Void,
    isolation: isolated (any Actor)? = #isolation
) -> _ContinuousObservationTrackingSubscription {
    if #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) {
        return _withContinuousObservationTracking(
            applying: block,
            onChange: onChange(),
            isolation: isolation
        )
    } else {
        return _ContinuousObservationTrackingSubscription(onCancel: {})
    }
}

@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *)
private func __internal_withContinuousObservationTracking(
    applying block: @escaping () -> Void,
    isCancelled: Swallow._OSUnfairLocked<Bool>,
    onChange: @escaping @Sendable () -> Void,
    isolation: isolated (any Actor)? = #isolation
) {
    let box = _UncheckedSendable(block)
    
    withObservationTracking {
        block()
    } onChange: {
        onChange()
        
        guard isCancelled.withCriticalScope({ !$0 }) else {
            return
        }
        
        Task {
            await __internal_withContinuousObservationTracking(
                applying: box.wrappedValue,
                isCancelled: isCancelled,
                onChange: onChange,
                isolation: isolation
            )
        }
    }
}

// MARK: - Auxiliary

public struct _ContinuousObservationTrackingSubscription: Sendable, Cancellable {
    private let onCancel: @Sendable () -> Void
    
    init(onCancel: @escaping @Sendable () -> Void) {
        self.onCancel = onCancel
    }
    
    public func cancel() {
        onCancel()
    }
}
