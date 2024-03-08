//
// Copyright (c) Vatsal Manot
//

import Combine
import Dispatch
import Swift

public final class RetainUntilCancel<Child: Cancellable>: Cancellable {
    @usableFromInline
    var instance: RetainUntilCancel?
    
    @usableFromInline
    var child: Child?
    
    @inlinable
    public init(_ cancellable: Child) {
        instance = self
        child = cancellable
    }
    
    @inlinable
    public func cancel() {
        instance = nil
        
        child?.cancel()
        child = nil
    }
}

// MARK: - API

extension Publisher {
    @discardableResult
    @inlinable
    public func retainSink(
        receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void),
        receiveValue: @escaping ((Output) -> Void)
    ) -> RetainUntilCancel<SingleAssignmentAnyCancellable> {
        let _cancellable = SingleAssignmentAnyCancellable()
        let cancellable = RetainUntilCancel(_cancellable)
        
        _cancellable.set(
            handleCancelOrCompletion { _ in
                cancellable.cancel()
            }
            .handleOutput(receiveValue)
            .sink()
        )
        
        return cancellable
    }

    @discardableResult
    @inlinable
    public func retainSink() -> RetainUntilCancel<SingleAssignmentAnyCancellable> {
        retainSink(
            receiveCompletion: { _ in },
            receiveValue: { _  in }
        )
    }

    @discardableResult
    @inlinable
    public func retainSink(
        receiveValue: @escaping ((Output) -> Void)
    ) -> RetainUntilCancel<SingleAssignmentAnyCancellable> where Failure == Never {
        retainSink(
            receiveCompletion: { _ in },
            receiveValue: receiveValue
        )
    }
}
